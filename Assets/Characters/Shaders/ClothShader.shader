Shader "WutheringWave/ClothShader"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" {}
        _Ramp ("Ramp", 2D) = "white" {}
        _NormalMap ("NormalMap", 2D) = "bump" {}
        _MatCapTex ("MatCapTex", 2D) = "white" {}
        _Shininess ("Shininess", Range(0.1, 100.0)) = 32.0
        _OutlineTex ("OutlineTex", 2D) = "Black" {}
        _OutlineWidth ("Outline Width", Range(0.01, 1)) = 0.01
        _ShadowEdgeStart ("Shadow Edge Start", Range(0,1)) = 0.2
        _ShadowEdgeEnd ("Shadow Edge End", Range(0,1)) = 0.7
        _ShadowValue ("Shadow Value", Range(0,1)) = 0.6
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            // Use shader model 3.0 target, to get nicer looking lighting
            #pragma target 3.0
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #define RAMP0 0.1
            #define RAMP1 0.3
            #define RAMP2 0.5
            #define RAMP3 0.7
            #define RAMP4 0.9

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 color : COLOR;
                float3 normal : NORMAL;
                float3 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 color : TEXCOORD1;
                float3 positionWS : TEXCOORD2;
                float3 normal : TEXCOORD3;
                float3 tangent : TEXCOORD4;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _NormalMap;
            sampler2D _MatCapTex;
            sampler2D _Ramp;
            float _Shininess;
            float _ShadowEdgeStart;
            float _ShadowEdgeEnd;
            float _ShadowValue;
            float4 _MainTex_ST;
            
            half LightingDiffuse(half3 lightDir, half3 normal, half atten)
            {
                half diff = max(dot(lightDir, normal),0.0);
                return diff * atten;
            }

            float3 CustomUnpackNormal(float4 packedNormal)
            {
                float3 normal;
                normal.xy = packedNormal.xy;
                normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
                return normal;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.positionWS = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.color = v.color;
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.tangent = UnityObjectToWorldDir(v.tangent);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                // sample the texture
                half4 albedo = tex2D(_MainTex, i.uv);
                
                float3 normal = normalize(i.normal);
                float3 tangent = normalize(i.tangent);
                float3 bitangent = cross(normal, tangent);
                float3x3 tbn = float3x3(tangent, bitangent, normal);

                float4 packedNormal = tex2D(_NormalMap, i.uv);
                float3 normalTS = CustomUnpackNormal(packedNormal);
                float3 normalWS = mul(normalTS, tbn);

                float3 lightDir = _WorldSpaceLightPos0.xyz;
                half3 lightColor = _LightColor0.xyz;
                half diffuse = LightingDiffuse(lightDir, normalWS, 1);

                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.positionWS);
                float3 halfVec = normalize(lightDir + viewDir);
                float specReal = pow(max(dot(normalWS, halfVec), 0.0), _Shininess);

                float cellShading = smoothstep(_ShadowEdgeStart, _ShadowEdgeEnd, diffuse + specReal);
                cellShading = lerp(_ShadowValue, 1, cellShading + albedo.a);
                
                // environment lighting
                half3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;

                // matcap
                float3 viewNormal = normalize(mul((float3x3)unity_MatrixV,normalWS));
                float2 matcapUV = 0.5 + 0.5 * viewNormal.xy;
                half4 matcapColor = tex2D(_MatCapTex, matcapUV);
                float matcapMask = tex2D(_NormalMap, i.uv).b;
                
                UNITY_APPLY_FOG(i.fogCoord, albedo);
                half4 ramppedCol = lightColor.xyzz *tex2D(_Ramp, float2(cellShading, RAMP0));
                
                return (albedo + matcapColor * matcapMask) * cellShading;
                return albedo * lightColor.rgbb * cellShading;
            }
            ENDCG
        }

        Pass
        {
            Tags {"LightMode"="ForwardBase"}
            Name "Outline"
            Cull Front
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #include "UnityCG.cginc"

            float _OutlineWidth;
            sampler2D _OutlineTex;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
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
                float4 vextex = v.vertex + float4(normalize(v.tangent), 0) * _OutlineWidth*0.01;
                o.vertex = UnityObjectToClipPos(vextex);
                o.uv = v.uv;
                o.color = v.color;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }
            

            half4 frag (v2f i) : SV_Target
            {
                half4 col = tex2D(_OutlineTex, i.uv);
                return col;
            }
            ENDCG
        }
    }
}








