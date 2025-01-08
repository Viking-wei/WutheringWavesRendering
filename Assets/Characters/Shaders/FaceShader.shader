Shader "WutheringWave/FaceShader"
{
    Properties
    {
        _MainTex ("Albedo", 2D) = "white" {}
        _FaceSDF ("FaceSDF", 2D) = "white" {}
        _Ramp ("Ramp", 2D) = "white" {}
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

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 color : COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 color : TEXCOORD1;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _FaceSDF_TexelSize;

            sampler2D _FaceSDF;
            sampler2D _Ramp;

            float FaceSDFShadow(sampler2D faceSDF, float2 uv, float3 lightDir, float3 forward, float3 up)
            {
                float3 lightDirIgnorey = normalize(float3(lightDir.x, 0, lightDir.z));
                float3 left = normalize(cross(forward, up));
                
                float flipSign = sign(dot(left, lightDirIgnorey));
                float4 sdf = tex2D(faceSDF, uv * float2(flipSign, 1));
                float sdfb = sdf.b;
                float sdfa = sdf.a;
                float sdfMix = (sdf.b+sdf.a)/2;
                forward = normalize(forward);
                float lgihtAtten = 1 - dot(lightDirIgnorey, forward);
                float shadow = smoothstep(lgihtAtten,lgihtAtten+0.2,sdf.r)+0.7;
                // float average = 0;
                // for(int i=-1; i<=1; i++)
                // {
                //     for(int j=-1; j<=1; j++)
                //     {
                //         float sdf = tex2D(faceSDF, uv * float2(flipSign, 1) + float2(i, j) * _FaceSDF_TexelSize.xy).a;
                //         float temp = step(lgihtAtten, sdf);
                //         average += temp;
                //     }
                // }
                // average /= 9;
                return saturate(shadow);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.color = v.color;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }
            

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                half4 color = tex2D(_MainTex, i.uv);
                float shadow = FaceSDFShadow(_FaceSDF, i.uv, _WorldSpaceLightPos0, float3(0, 0, 1), float3(0, 1, 0));
                half4 faceMask = half4(i.color, 1);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                //return faceMask.g;
                return color * shadow;
            }
            ENDCG
        }
    }
}
