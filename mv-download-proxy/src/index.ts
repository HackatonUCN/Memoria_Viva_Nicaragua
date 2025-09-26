/**
 * Welcome to Cloudflare Workers! This is your first worker.
 *
 * - Run `npm run dev` in your terminal to start a development server
 * - Open a browser tab at http://localhost:8787/ to see your worker in action
 * - Run `npm run deploy` to publish your worker
 *
 * Bind resources to your worker in `wrangler.jsonc`. After adding bindings, a type definition for the
 * `Env` object can be regenerated with `npm run cf-typegen`.
 *
 * Learn more at https://developers.cloudflare.com/workers/
 */

function deriveFromCloudinaryUrl(u: string, cloudName: string): { resourceType: string; publicIdNoExt: string; format: string } | null {
  try {
    const url = new URL(u);
    if (!url.host.includes('res.cloudinary.com')) return null;
    const segs = url.pathname.split('/').filter(Boolean);
    
    // Log for debugging
    console.log(`[Worker] URL segments: ${JSON.stringify(segs)}`);
    
    // In the standard Cloudinary URL pattern:
    // https://res.cloudinary.com/cloud_name/resource_type/delivery_type/version/public_id
    // The resource type is typically the second element after the cloud name
    // In this case, we know the host is res.cloudinary.com, so first segment is likely cloud_name
    
    // Resource type is usually the second segment (index 1)
    const resourceType = segs.length > 1 ? segs[1] : 'raw';
    
    // Find upload segment (delivery type)
    const uploadIdx = segs.indexOf('upload');
    if (uploadIdx === -1) return null;
    
    // Extract everything after 'upload'
    let after = segs.slice(uploadIdx + 1);
    if (after.length === 0) return null;
    
    // Handle version number if present (e.g., v1234567890)
    if (after[0] && after[0].startsWith('v')) after = after.slice(1);
    if (after.length === 0) return null;
    
    // Get the last segment which usually contains the filename
    const last = after[after.length - 1];
    const dot = last.lastIndexOf('.');
    
    // Extract format (file extension)
    const format = dot > 0 ? last.slice(dot + 1).toLowerCase() : '';
    
    // Extract name without extension
    const lastNoExt = dot > 0 ? last.slice(0, dot) : last;
    
    // Build the full publicId without extension
    const publicIdNoExt = [...after.slice(0, -1), lastNoExt].join('/');
    
    console.log(`[Worker] Derived: resourceType=${resourceType}, publicIdNoExt=${publicIdNoExt}, format=${format}`);
    
    return { resourceType, publicIdNoExt, format };
  } catch (err) {
    console.log(`[Worker] Error deriving from URL: ${err}`);
    return null;
  }
}

// Generate a direct signed URL using Cloudflare Workers native crypto API
async function tryDirectSignedUrl(env: Env, publicIdNoExt: string, resourceType: string, format: string): Promise<string | null> {
  try {
    // Calculate signature using SHA1 with Cloudflare Workers crypto
    const timestamp = Math.floor(Date.now() / 1000);
    const expiresAt = timestamp + 3600; // URL valid for 1 hour
    
    // Create signature base
    const toSign = `public_id=${publicIdNoExt}&timestamp=${timestamp}${env.CLOUDINARY_API_SECRET}`;
    
    // Use Cloudflare Workers native crypto
    const msgUint8 = new TextEncoder().encode(toSign);
    const hashBuffer = await crypto.subtle.digest('SHA-1', msgUint8);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const signature = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
    
    // Construct signed URL with authentication params
    const params = new URLSearchParams({
      'api_key': env.CLOUDINARY_API_KEY,
      'timestamp': String(timestamp),
      'signature': signature
    });
    
    // Try different delivery formats
    const formats = [
      `https://res.cloudinary.com/${env.CLOUDINARY_CLOUD_NAME}/${resourceType}/authenticated/v${timestamp}/${publicIdNoExt}.${format}?${params.toString()}`,
      `https://res.cloudinary.com/${env.CLOUDINARY_CLOUD_NAME}/${resourceType}/private/v${timestamp}/${publicIdNoExt}.${format}?${params.toString()}`,
      `https://res.cloudinary.com/${env.CLOUDINARY_CLOUD_NAME}/${resourceType}/authenticated/${publicIdNoExt}.${format}?${params.toString()}`,
      `https://res.cloudinary.com/${env.CLOUDINARY_CLOUD_NAME}/${resourceType}/private/${publicIdNoExt}.${format}?${params.toString()}`
    ];
    
    console.log(`[Worker] Generated signed URLs to try`);
    
    // Try each format
    for (const signedUrl of formats) {
      try {
        console.log(`[Worker] Trying signed URL: ${signedUrl.substring(0, 50)}...`);
        const testResponse = await fetch(signedUrl, { method: 'HEAD' });
        if (testResponse.ok || testResponse.status === 302) {
          console.log(`[Worker] Signed URL succeeded with status ${testResponse.status}`);
          return signedUrl;
        } else {
          console.log(`[Worker] Signed URL failed with status ${testResponse.status}`);
        }
      } catch (err) {
        console.log(`[Worker] Error testing signed URL: ${err}`);
      }
    }
    
    return null;
  } catch (err) {
    console.log(`[Worker] Error generating direct signed URL: ${err}`);
    return null;
  }
}

// Try multiple variations of the public ID to handle different Cloudinary URL patterns
async function tryMultiplePublicIdFormats(env: Env, publicIdNoExt: string, resourceType: string, format: string): Promise<string | null> {
  // First try direct signed URL approach
  let result = await tryDirectSignedUrl(env, publicIdNoExt, resourceType, format);
  if (result) return result;
  
  // Then try the original private_download approach
  result = await tryPrivateDownload(env, publicIdNoExt, resourceType, format);
  if (result) return result;
  
  // Try with last segment removed (in case of IDs with extra filename at the end)
  const segments = publicIdNoExt.split('/');
  if (segments.length > 1) {
    const withoutLast = segments.slice(0, -1).join('/');
    console.log(`[Worker] Trying without last segment: ${withoutLast}`);
    result = await tryPrivateDownload(env, withoutLast, resourceType, format);
    if (result) return result;
  }
  
  // Try with potential parent folder removed
  const lastSegment = segments[segments.length - 1];
  console.log(`[Worker] Trying just last segment: ${lastSegment}`);
  result = await tryPrivateDownload(env, lastSegment, resourceType, format);
  if (result) return result;
  
  // If PDF ends with numbers, try without them (common pattern)
  if (lastSegment.includes('.pdf')) {
    const beforePdf = publicIdNoExt.substring(0, publicIdNoExt.lastIndexOf('.pdf'));
    console.log(`[Worker] Trying before PDF suffix: ${beforePdf}`);
    result = await tryPrivateDownload(env, beforePdf, resourceType, format);
    if (result) return result;
  }
  
  // Try with different resource types
  if (resourceType !== 'image') {
    console.log(`[Worker] Trying with resource type=image`);
    result = await tryPrivateDownload(env, publicIdNoExt, 'image', format);
    if (result) return result;
  }
  
  if (resourceType !== 'auto') {
    console.log(`[Worker] Trying with resource type=auto`);
    result = await tryPrivateDownload(env, publicIdNoExt, 'auto', format);
    if (result) return result;
  }
  
  return null;
}

async function tryPrivateDownload(env: Env, publicIdNoExt: string, resourceType: string, format: string): Promise<string | null> {
  // Para PDFs, intentamos primero usar el endpoint específico para raw assets
  if (format.toLowerCase() === 'pdf') {
    console.log(`[Worker] Trying raw asset approach for PDF: ${publicIdNoExt}`);
    
    // Intentar construir una URL firmada para raw assets (PDFs)
    try {
      const timestamp = Math.floor(Date.now() / 1000);
      const expiresAt = timestamp + 3600; // 1 hora
      
      // Extraemos el último segmento del ID (el ID generado automáticamente)
      const segments = publicIdNoExt.split('/');
      const lastSegment = segments[segments.length - 1];
      console.log(`[Worker] Last segment of ID (auto-generated part): ${lastSegment}`);
      
      // Construir una firma especial para PDFs
      // Intenta con varios tipos de recursos y variaciones del ID
      const pdfResourceTypes = ['raw', 'image', 'private', 'authenticated'];
      const idVariations = [
        publicIdNoExt,                // ID completo
        lastSegment,                  // Solo el último segmento (ID autogenerado)
        `memoria_viva/${lastSegment}` // Carpeta base + ID autogenerado
      ];
      
      for (const rt of pdfResourceTypes) {
        for (const idVar of idVariations) {
          console.log(`[Worker] Trying with ${rt}/${idVar}`);
          
          // Probar diferentes formatos de URL para PDFs
          const urlFormats = [
            // URL directa con firma (resource_type/delivery_type/publicId.pdf) - Acceso público
            `https://res.cloudinary.com/${env.CLOUDINARY_CLOUD_NAME}/${rt}/upload/${idVar}.${format}`,
            
            // URL directa con firma - Public con API key
            `https://res.cloudinary.com/${env.CLOUDINARY_CLOUD_NAME}/${rt}/upload/${idVar}.${format}?api_key=${env.CLOUDINARY_API_KEY}`,
            
            // URL con parámetro de adjunto (fl_attachment) - Para forzar descarga
            `https://res.cloudinary.com/${env.CLOUDINARY_CLOUD_NAME}/${rt}/upload/fl_attachment/${idVar}.${format}`,
            
            // URL firmada completa para acceso seguro
            `https://res.cloudinary.com/${env.CLOUDINARY_CLOUD_NAME}/${rt}/upload/${idVar}.${format}?timestamp=${timestamp}&api_key=${env.CLOUDINARY_API_KEY}&signature=${await generateSignature(`public_id=${idVar}&timestamp=${timestamp}`, env.CLOUDINARY_API_SECRET)}`,
            
            // Acceso como raw resource explícito
            `https://res.cloudinary.com/${env.CLOUDINARY_CLOUD_NAME}/raw/upload/${idVar}.${format}`,
            
            // Acceso directo al archivo PDF (sin transformaciones)
            `https://res.cloudinary.com/${env.CLOUDINARY_CLOUD_NAME}/${rt}/upload/q_auto/${idVar}.${format}`
          ];
          
          for (const url of urlFormats) {
            console.log(`[Worker] Trying PDF URL: ${url.substring(0, 70)}...`);
            try {
              const response = await fetch(url, { method: 'HEAD' });
              console.log(`[Worker] Response status for ${idVar}: ${response.status}`);
              
              if (response.ok || response.status === 302) {
                console.log(`[Worker] Found working PDF URL with resource type ${rt} and ID ${idVar}`);
                return url;
              }
            } catch (err) {
              console.log(`[Worker] Error checking PDF URL: ${err}`);
            }
          }
        }
      }
    } catch (err) {
      console.log(`[Worker] Error generating PDF URL: ${err}`);
    }
  }

  // Si no es un PDF o el método anterior falló, usar el enfoque original
  const endpoint = `https://api.cloudinary.com/v1_1/${env.CLOUDINARY_CLOUD_NAME}/${resourceType}/private_download`;
  const expiresAt = Math.floor(Date.now() / 1000) + 60;
  const auth = 'Basic ' + btoa(`${env.CLOUDINARY_API_KEY}:${env.CLOUDINARY_API_SECRET}`);
  const types = ['upload', 'authenticated', 'private'];
  console.log(`[Worker] Trying private_download for publicId=${publicIdNoExt} resourceType=${resourceType} format=${format}`);
  
  for (const type of types) {
    const form = new URLSearchParams();
    form.set('public_id', publicIdNoExt);
    if (format) form.set('format', format);
    form.set('expires_at', String(expiresAt));
    form.set('attachment', 'true');
    form.set('type', type);
    console.log(`[Worker] Trying type=${type} for ${publicIdNoExt}`);
    const r = await fetch(endpoint, { method: 'POST', headers: { 'Authorization': auth, 'Content-Type': 'application/x-www-form-urlencoded' }, body: form });
    console.log(`[Worker] Response status=${r.status} for type=${type}`);
    if (r.ok) {
      const data = await r.json();
      const url = (data as any).url as string | undefined;
      console.log(`[Worker] Got URL=${url ? 'yes' : 'no'} for type=${type}`);
      if (url) return url;
    } else {
      // Log more detailed error information
      try {
        const errorText = await r.text();
        console.log(`[Worker] Error response for ${type}: ${errorText.substring(0, 200)}...`);
      } catch (err) {
        console.log(`[Worker] Could not read error text: ${err}`);
      }
      
      if (r.status !== 404 && r.status !== 401) {
        // Non-retriable error
        console.log(`[Worker] Non-retriable error ${r.status} for type=${type}`);
        return null;
      }
    }
  }
  console.log(`[Worker] All types failed for publicId=${publicIdNoExt}`);
  return null;
}

// Función auxiliar para generar firma SHA1
async function generateSignature(stringToSign: string, apiSecret: string): Promise<string> {
  const msgUint8 = new TextEncoder().encode(stringToSign + apiSecret);
  const hashBuffer = await crypto.subtle.digest('SHA-1', msgUint8);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    try {
      const urlObj = new URL(request.url);
      let id = urlObj.searchParams.get('id') || '';
      const directUrl = urlObj.searchParams.get('url') || '';
      const signedUrl = urlObj.searchParams.get('signed_url') || ''; // New param for direct signed URL
      const fileName = (urlObj.searchParams.get('filename') || 'documento.pdf').replace(/["\\]/g, '');
      let resourceType = urlObj.searchParams.get('rt') || 'raw';
      let format = urlObj.searchParams.get('format') || 'pdf';

      console.log(`[Worker] Request id=${id} url=${directUrl} signed_url=${signedUrl?.substring(0, 30)}... rt=${resourceType} format=${format}`);

      if (request.method === 'HEAD') {
        return new Response(null, { status: 204 });
      }

      let sourceUrl = '';
      
      // If a signed URL is provided directly, use it
      if (signedUrl) {
        console.log(`[Worker] Using provided signed URL`);
        sourceUrl = signedUrl;
      }
      else if (id) {
        // Keep intermediate segments intact, only strip extension from the last segment if it matches format
        const originalId = id;
        const parts = id.split('/');
        const last = parts.pop() || '';
        const dot = last.lastIndexOf('.');
        // Only remove extension if it matches our format param
        const ext = dot > 0 ? last.slice(dot + 1).toLowerCase() : '';
        const lastNoExt = dot > 0 && ext === format.toLowerCase() ? last.slice(0, dot) : last;
        id = [...parts, lastNoExt].join('/');
        console.log(`[Worker] Normalized id=${id}`);
        
        // Try several variations of the ID
        let pd = null;
        
        // Try the normalized ID first
        pd = await tryMultiplePublicIdFormats(env, id, resourceType, format);
        if (pd) {
          sourceUrl = pd;
        } else {
          // Try without the last segment entirely (in case it's a random file ID)
          if (parts.length > 0) {
            const withoutLast = parts.join('/');
            console.log(`[Worker] Trying ID without last segment: ${withoutLast}`);
            pd = await tryMultiplePublicIdFormats(env, withoutLast, resourceType, format);
          }
          
          // If still not found, try with just the last part (maybe it's a pure asset ID)
          if (!pd && last) {
            console.log(`[Worker] Trying with just last segment: ${lastNoExt}`);
            pd = await tryMultiplePublicIdFormats(env, lastNoExt, resourceType, format);
          }
          
          // If still not found, try stripping any .pdf parts within the path
          if (!pd && id.includes('.pdf/')) {
            const strippedId = id.split('.pdf/').join('/');
            console.log(`[Worker] Trying with .pdf parts removed: ${strippedId}`);
            pd = await tryMultiplePublicIdFormats(env, strippedId, resourceType, format);
          }
          
          if (pd) {
            sourceUrl = pd;
          } else {
            return new Response('Cloudinary private_download 404 - No se pudo encontrar el archivo', { status: 404 });
          }
        }
      } else if (directUrl) {
        // Usar directamente la URL proporcionada sin intentar private_download
        console.log(`[Worker] Using direct URL immediately: ${directUrl}`);
        sourceUrl = directUrl;
      } else {
        return new Response('Falta id o url', { status: 400 });
      }

      const upstream = await fetch(sourceUrl);
      console.log(`[Worker] Upstream fetch status=${upstream.status} ct=${upstream.headers.get('content-type')}`);
      if (!upstream.ok) return new Response(`Cloudinary devolvió ${upstream.status}`, { status: upstream.status });

      const ct = upstream.headers.get('content-type') || 'application/octet-stream';
      const headers = new Headers(upstream.headers);
      headers.set('Content-Type', ct);
      headers.set('Content-Disposition', `attachment; filename="${fileName}"`);
      headers.set('Cache-Control', 'private, max-age=60');

      return new Response(upstream.body, { status: 200, headers });
    } catch (e) {
      return new Response('Proxy error', { status: 502 });
		}
	},
} satisfies ExportedHandler<Env>;

interface Env {
  CLOUDINARY_CLOUD_NAME: string;
  CLOUDINARY_API_KEY: string;
  CLOUDINARY_API_SECRET: string;
}