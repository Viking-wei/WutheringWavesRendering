Shader"WutheringWave/Hair"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SpecularMap ("SpecularMap", 2D) = "white" {}
        _Specular ("Specular", Range(0,1)) = 0.5
        _Shininess ("Shininess", Range(0.1, 100.0)) = 32.0
        _NormalMap ("NormalMap", 2D) = "bump" {}
        _OutlineTex ("OutlineTex", 2D) = "Black" {}
        _OutlineColor ("Outline Color", Color) = (0,0,0,1)
        _OutlineWidth ("Outline Width", Range(0.1, 3)) = 0.5
        _OutlineFadeDistance ("Outline Fade Distance", Range(0, 10)) = 4
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
            Tags {"LightMode"="ForwardBase"}
            Name "Hair"
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "UnityPBSLighting.cginc"
            #include "Utilities.cginc"

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

            float _Specular;
            float _Shininess;
            float _ShadowEdgeStart;
            float _ShadowEdgeEnd;
            float _ShadowValue;

            sampler2D _MainTex;
            sampler2D _NormalMap;
            sampler2D _SpecularMap;
            float4 _MainTex_ST;

            
            
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

            half3 frag (v2f i) : SV_Target
            {
                half4 albedo = tex2D(_MainTex, i.uv);
                float3 normal = normalize(i.normal);
                float3 tangent = normalize(i.tangent);
                float3 normalWS = SampleNormalMapTraditional(_NormalMap, i.uv, normal, tangent);
                //normalWS = UnityObjectToWorldNormal(normal);
                    
                float3 lightDir = _WorldSpaceLightPos0.xyz;
                half diffuse = LightingDiffuse(lightDir, normalWS, 1);
                
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.positionWS);
                float3 halfVec = normalize(lightDir + viewDir);
                //float specReal = pow(max(dot(normalWS, halfVec), 0.0), _Shininess);
                float specReal = 0;
                float specFake = tex2D(_SpecularMap, i.uv);
                half3 specular = (specReal + specFake)*_Specular;
                float cellShading = smoothstep(_ShadowEdgeStart, _ShadowEdgeEnd, diffuse);
                cellShading = lerp(_ShadowValue, 1, cellShading);
                
                // environment lighting
                half3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;

                half3 finalColor = albedo * cellShading + specular + ambient;
                UNITY_APPLY_FOG(i.fogCoord, finalColor);
                return finalColor;
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
            #include "OutlinePass.cginc"
            ENDCG
        }


	    Pass
	    {
		    Name "ShadowCaster"
		    Tags { "LightMode" = "ShadowCaster" }
		    ZWrite On
		    ZTest LEqual

            CGPROGRAM
            // compile directives
            #pragma vertex vert_surf
            #pragma fragment frag_surf

            #include "UnityCG.cginc"

            #pragma target 5.0

            #pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
            #pragma multi_compile_shadowcaster

            // -------- variant for: <when no other keywords are defined>
            #if !defined(INSTANCING_ON)

            #define INTERNAL_DATA
            #define WorldReflectionVector(data,normal) data.worldRefl
            #define WorldNormalVector(data,normal) normal

            // Original surface shader snippet:
            #line 10 ""
            #ifdef DUMMY_PREPROCESSOR_TO_WORK_AROUND_HLSL_COMPILER_LINE_HANDLING
            #endif

            struct v2f_surf {
              V2F_SHADOW_CASTER;

              UNITY_VERTEX_INPUT_INSTANCE_ID
              UNITY_VERTEX_OUTPUT_STEREO
            };

            // vertex shader
            inline v2f_surf vert_surf (appdata_full v) {
              v2f_surf o;
              UNITY_INITIALIZE_OUTPUT(v2f_surf,o);
              TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
              return o;
            }

            // fragment shader
            inline fixed4 frag_surf (v2f_surf IN) : SV_Target {
 	            SHADOW_CASTER_FRAGMENT(IN)
            }
            #endif
            ENDCG
        }
    }
}
