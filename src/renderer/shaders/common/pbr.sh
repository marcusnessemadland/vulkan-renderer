#ifndef PBR_SH_HEADER_GUARD
#define PBR_SH_HEADER_GUARD

#include "samplers.sh"

// Only define this if you need to retrieve the material parameters
// without it you can still use the struct definition or BRDF functions
#ifdef READ_MATERIAL

SAMPLER2D(s_texBaseColor,         SAMPLER_PBR_BASECOLOR);
SAMPLER2D(s_texMetallic,          SAMPLER_PBR_METAL);
SAMPLER2D(s_texRoughness,         SAMPLER_PBR_ROUGHNESS);
SAMPLER2D(s_texNormal,            SAMPLER_PBR_NORMAL);
SAMPLER2D(s_texOcclusion,         SAMPLER_PBR_OCCLUSION);
SAMPLER2D(s_texEmissive,          SAMPLER_PBR_EMISSIVE);

uniform vec4 u_baseColorFactor;
uniform vec4 u_metallicRoughnessNormalOcclusionFactor;
uniform vec4 u_emissiveFactorVec;
uniform vec4 u_hasTextures;

#define u_hasBaseColorTexture         ((uint(u_hasTextures.x) & uint(1 << 0)) != uint(0))
#define u_hasMetallicTexture          ((uint(u_hasTextures.x) & uint(1 << 1)) != uint(0))
#define u_hasRoughnessTexture         ((uint(u_hasTextures.x) & uint(1 << 2)) != uint(0))
#define u_hasNormalTexture            ((uint(u_hasTextures.x) & uint(1 << 3)) != uint(0))
#define u_hasOcclusionTexture         ((uint(u_hasTextures.x) & uint(1 << 4)) != uint(0))
#define u_hasEmissiveTexture          ((uint(u_hasTextures.x) & uint(1 << 5)) != uint(0))

#define u_metallicFactor          (u_metallicRoughnessNormalOcclusionFactor.x)
#define u_roughnessFactor         (u_metallicRoughnessNormalOcclusionFactor.y)
#define u_normalScale             (u_metallicRoughnessNormalOcclusionFactor.z)
#define u_occlusionStrength       (u_metallicRoughnessNormalOcclusionFactor.w)
#define u_emissiveFactor          (u_emissiveFactorVec.xyz)

#endif

#define PI     (3.14159265359)
#define INV_PI (0.31830988618)

struct PBRMaterial
{
    vec4 albedo;
    float metallic;
    float roughness;
    vec3 normal;
    float occlusion;
    vec3 emissive;

    // Calculated from the above
    vec3 diffuseReflectance;
    vec3 fresnelReflectance;
    float roughnessSquared; 
};

#ifdef READ_MATERIAL

vec4 pbrBaseColor(vec2 texcoord)
{
    if(u_hasBaseColorTexture)
    {
        return texture2D(s_texBaseColor, texcoord) * u_baseColorFactor;
    }
    else
    {
        return u_baseColorFactor;
    }
}

float pbrMetallic(vec2 texcoord)
{
    if(u_hasMetallicTexture)
    {
        return texture2D(s_texMetallic, texcoord).x * u_metallicFactor;
    }
    else
    {
        return u_metallicFactor;
    }
}

float pbrRoughness(vec2 texcoord)
{
    if(u_hasRoughnessTexture)
    {
        return texture2D(s_texRoughness, texcoord).x * u_roughnessFactor;
    }
    else
    {
        return u_roughnessFactor;
    }
}

vec3 pbrNormal(vec2 texcoord)
{
    if(u_hasNormalTexture)
    {
        // the normal scale can cause problems and serves no real purpose
        // normal compression and BRDF calculations assume unit length
        return normalize((texture2D(s_texNormal, texcoord).rgb * 2.0) - 1.0); // * u_normalScale;
    }
    else
    {
        // the up vector (w) in tangent space is the default normal
        // that's why normal maps are mostly blue
        return vec3(0.0, 0.0, 1.0);
    }
}

float pbrOcclusion(vec2 texcoord)
{
    if(u_hasOcclusionTexture)
    {
        // occludedColor = lerp(color, color * <sampled occlusion texture value>, <occlusion strength>)
        float occlusion = texture2D(s_texOcclusion, texcoord).r;
        return occlusion + (1.0 - occlusion) * (1.0 - u_occlusionStrength);
    }
    else
    {
        return 1.0;
    }
}

vec3 pbrEmissive(vec2 texcoord)
{
    if(u_hasEmissiveTexture)
    {
        return texture2D(s_texEmissive, texcoord).rgb * u_emissiveFactor;
    }
    else
    {
        return u_emissiveFactor;
    }
}

PBRMaterial pbrInitMaterial(PBRMaterial mat);

PBRMaterial pbrMaterial(vec2 texcoord)
{
    PBRMaterial mat;

    // Read textures/uniforms

    mat.albedo = pbrBaseColor(texcoord);
    mat.metallic  = pbrMetallic(texcoord);
    mat.roughness = pbrRoughness(texcoord);
    mat.normal = pbrNormal(texcoord);
    mat.occlusion = pbrOcclusion(texcoord);
    mat.emissive = pbrEmissive(texcoord);

    mat = pbrInitMaterial(mat);

    return mat;
}

#endif // READ_MATERIAL

PBRMaterial pbrInitMaterial(PBRMaterial mat)
{
    // Taken directly from GLTF 2.0 specs
    // this can be precalculated instead of evaluating it in the BRDF for every light

    const vec3 dielectricSpecular = vec3(0.04, 0.04, 0.04);
    const vec3 black = vec3(0.0, 0.0, 0.0);

    // metals have no diffuse reflection so the albedo value stores F0 (reflectance at normal incidence) instead
    // dielectrics are assumed to have F0 = 0.04 which equals an IOR of 1.5
    mat.diffuseReflectance = mix(mat.albedo.rgb * (vec3_splat(1.0) - dielectricSpecular), black, mat.metallic);
    mat.fresnelReflectance = mix(dielectricSpecular, mat.albedo.rgb, mat.metallic);
    // perceptual roughness to roughness
    mat.roughnessSquared= mat.roughness * mat.roughness;
    // prevent division by 0
    mat.roughnessSquared= max(mat.roughnessSquared, 0.01);

    return mat;
}

// no screenspace derivatives in vertex or compute
#if BGFX_SHADER_TYPE_FRAGMENT

// Reduce specular aliasing by producing a modified roughness value

// Tokuyoshi et al. 2019. Improved Geometric Specular Antialiasing.
// http://www.jp.square-enix.com/tech/library/pdf/ImprovedGeometricSpecularAA.pdf
float specularAntiAliasing(vec3 N, float a)
{
    // normal-based isotropic filtering
    // this is originally meant for deferred rendering but is a bit simpler to implement than the forward version
    // saves us from calculating uv offsets and sampling textures for every light

    const float SIGMA2 = 0.25; // squared std dev of pixel filter kernel (in pixels)
    const float KAPPA  = 0.18; // clamping threshold

    vec3 dndu = dFdx(N);
    vec3 dndv = dFdy(N);
    float variance = SIGMA2 * (dot(dndu, dndu) + dot(dndv, dndv));
    float kernelRoughness2 = min(2.0 * variance, KAPPA);
    return saturate(a + kernelRoughness2);
}

#endif

// Physically based shading
// Metallic + roughness workflow (GLTF 2.0 core material spec)
// BRDF, no sub-surface scattering
// https://github.com/KhronosGroup/glTF/tree/master/specification/2.0#metallic-roughness-material
// Some GLSL code taken from
// https://google.github.io/filament/Filament.md.html
// and
// https://learnopengl.com/PBR/Lighting

// Schlick approximation to Fresnel equation
vec3 F_Schlick(float VoH, vec3 F0)
{
    float f = pow(1.0 - VoH, 5.0);
    return f + F0 * (1.0 - f);
}

// Normal Distribution Function
// (aka specular distribution)
// distribution of microfacets

// Bruce Walter et al. 2007. Microfacet Models for Refraction through Rough Surfaces.
// equivalent to Trowbridge-Reitz
float D_GGX(float NoH, float a)
{
    a = NoH * a;
    float k = a / (1.0 - NoH * NoH + a * a);
    return k * k * INV_PI;
}

// Visibility function
// = Geometric Shadowing/Masking Function G, divided by the denominator of the Cook-Torrance BRDF (4 NoV NoL)
// G is the probability of the microfacet being visible in the outgoing (masking) or incoming (shadowing) direction

// Heitz 2014. Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs.
// http://jcgt.org/published/0003/02/03/paper.pdf
// based on height-correlated Smith-GGX
float V_SmithGGXCorrelated(float NoV, float NoL, float a)
{
    float a2 = a * a;
    float GGXV = NoL * sqrt(NoV * NoV * (1.0 - a2) + a2);
    float GGXL = NoV * sqrt(NoL * NoL * (1.0 - a2) + a2);
    return 0.5 / (GGXV + GGXL);
}

// version without height-correlation
float V_SmithGGX(float NoV, float NoL, float a)
{
    float a2 = a * a;
    float GGXV = NoV + sqrt(NoV * NoV * (1.0 - a2) + a2);
    float GGXL = NoL + sqrt(NoL * NoL * (1.0 - a2) + a2);
    return 1.0 / (GGXV * GGXL);
}

// Lambertian diffuse BRDF
// uniform color
float Fd_Lambert()
{
    // normalize to conserve energy
    // cos integrates to pi over the hemisphere
    // incoming light is multiplied by cos and BRDF
    return INV_PI;
}

// https://github.com/KhronosGroup/glTF/tree/master/specification/2.0#appendix-b-brdf-implementation
vec3 BRDF(vec3 v, vec3 l, vec3 n, float NoV, float NoL, PBRMaterial mat)
{
    // V is the normalized vector from the shading location to the eye
    // L is the normalized vector from the shading location to the light
    // N is the surface normal in the same space as the above values
    // H is the half vector, where H = normalize(L+V)

    vec3 h = normalize(l + v);
    float NoH = saturate(dot(n, h));
    float VoH = saturate(dot(v, h));

    // specular BRDF
    float D = D_GGX(NoH, mat.roughnessSquared);
    vec3 F = F_Schlick(VoH, mat.fresnelReflectance);
    float V = V_SmithGGXCorrelated(NoV, NoL, mat.roughnessSquared);
    vec3 Fr = F * (V * D);

    // diffuse BRDF
    vec3 Fd = mat.diffuseReflectance * Fd_Lambert();

    return Fr + (1.0 - F) * Fd;
}

#endif // PBR_SH_HEADER_GUARD
