#include "UnityCG.cginc"

half LightingDiffuse(half3 lightDir, half3 normal, half atten)
{
    half diff = max(dot(lightDir, normal),0.0);
    return diff * atten;
}
            
float Remap(float value, float srcMin, float srcMax, float dstMin, float dstMax)
{
    float normalizedValue = (value - srcMin) / (srcMax - srcMin);
    return dstMin + normalizedValue * (dstMax - dstMin);
}

float3 CustomUnpackNormal(float4 packedNormal)
{
    float3 normal;
    normal.xy = packedNormal.xy;
    normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
    return normal;
}

float3 SampleNormalMap(sampler2D normalMap, float2 uv, float3 originNormal, float3 originTangent)
{
    float3 normal = normalize(UnityObjectToWorldNormal(originNormal));
    float3 tangent = normalize(mul(unity_ObjectToWorld,originTangent));
    float3 bitangent = cross(normal, tangent);
    float3x3 tbn = float3x3(tangent, bitangent, normal);

    float4 packedNormal = tex2D(normalMap, uv);
    float3 normalTS = CustomUnpackNormal(packedNormal);
    float3 normalWS = mul(normalTS, tbn);
    
    return normalize(normalWS);
}

float3 SampleNormalMapTraditional(sampler2D normalMap, float2 uv, float3 originNormal, float3 originTangent)
{
    
    float3 normal = normalize(UnityObjectToWorldNormal(originNormal));
    float3 tangent = normalize(mul(unity_ObjectToWorld,originTangent));
    float3 bitangent = cross(normal, tangent);
    float3x3 tbn = float3x3(tangent, bitangent, normal);

    float4 packedNormal = tex2D(normalMap, uv);
    float3 normalTS = UnpackNormal(packedNormal);
    float3 normalWS = mul(normalTS, tbn);
    
    return normalize(normalWS);
}


half3 RimLighting(float3 normal, float3 smoothNormal, float nBlend, float rimLength, float rimLightWidth, sampler2D depthTexture,half3 color, float3 positionSS, float3 viewDir, float3 lightDir)
{
    float2 lightVS = normalize(mul((float3x3)UNITY_MATRIX_V, lightDir).xy);
    float2 normalVS = normalize(mul((float3x3)UNITY_MATRIX_V, lerp(normal, smoothNormal, nBlend)).xy);
    float lDotN = saturate(dot(normalVS, lightVS) + rimLength * 0.1);
    float2 ssUV = positionSS + normalVS * lDotN * rimLightWidth * color.b * 40/*GetSSRimScale(posInput.linearDepth)*/;
    float depth = tex2D(depthTexture,clamp(ssUV, 0, _ScreenParams.xy - 1));
    float depthScene = LinearEyeDepth(depth);
//     float depthDiff = depthScene - posInput.linearDepth;
//     float intensity = smoothstep(0.24 * _RimLightFeather * posInput.linearDepth, 0.25 * posInput.linearDepth, depthDiff);
//     intensity *= lerp(1, _RimLightIntInShadow, context.shadowStep) * _RimLightIntensity * mask;
//             
//     float3 ssColor = intensity * lerp(1, context.brightBaseColor, _RimLightBlend)
//     * lerp(_RimLightColor.rgb, context.pointLightColor, luminance * _RimLightBlendPoint);
//             
//     c = max(c, ssColor);
//     return col;
}

