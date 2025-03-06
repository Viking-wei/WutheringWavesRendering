#pragma multi_compile_fog
#include "UnityCG.cginc"
#define FADE_BEGIN_DIST 0.6

// Properties
float _OutlineWidth;
float _OutlineFadeDistance;
half4 _OutlineColor;
sampler2D _OutlineTex;

float CustomDecayFunction(float x, float decayFactor)
{
    return exp(-decayFactor * x) * (1.0 - x);
}



struct appdata
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float2 uv2 : TEXCOORD1;
    float2 uv3 : TEXCOORD2;
    float3 color : COLOR;
    float3 normal : NORMAL;
    float3 tangent : TANGENT;
};

struct v2f
{
    float2 uv : TEXCOORD0;
    float3 color : TEXCOORD1;
    UNITY_FOG_COORDS(1)
    float4 vertex : SV_POSITION;
};

v2f vert (appdata v)
{
    v2f o;
    UNITY_INITIALIZE_OUTPUT(v2f, o);
    float3 positionWS = mul(unity_ObjectToWorld, v.vertex).xyz;
    float distance = length(positionWS - _WorldSpaceCameraPos);
    float4 vertex = UnityObjectToClipPos(v.vertex);
    //houdini axis to unity axis
    float3 normal = normalize(float3(v.uv2,v.uv3.x) * float3(-1 ,1, 1));
    //normal = v.normal;
    float3 viewNormal = mul((float3x3)UNITY_MATRIX_IT_MV, normal);
    float3 ndcNormal = normalize(TransformViewToProjection(viewNormal.xyz)) * vertex.w;
    float4 nearUpperRight = mul(unity_CameraInvProjection, float4(1, 1, UNITY_NEAR_CLIP_VALUE, _ProjectionParams.y));
    float aspect = abs(nearUpperRight.y / nearUpperRight.x);
    ndcNormal.x *= aspect;
    float fadeRate = saturate((distance - FADE_BEGIN_DIST) / (_OutlineFadeDistance - FADE_BEGIN_DIST));
    fadeRate =saturate(CustomDecayFunction(fadeRate, 5));
    vertex.xy += 0.01 * _OutlineWidth * ndcNormal.xy * fadeRate;
    o.vertex = vertex;
    o.uv = v.uv;
    o.color = v.color;
    UNITY_TRANSFER_FOG(o,o.vertex);
    return o;
}
            

half4 frag (v2f i) : SV_Target
{
    half4 lowTexture = tex2D(_OutlineTex, i.uv);
    half4 outlineCol = _OutlineColor;
    return outlineCol;
}

