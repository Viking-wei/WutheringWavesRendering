Shader "WutheringWave/Hair"
{
    Properties
    {
        _MainTex ("Base Texture", 2D) = "white" {}
        _Color ("Tint Color", Color) = (1,1,1,1)
        _Alpha ("Alpha Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        LOD 100

        Pass
        {
            Tags { "LightMode"="ForwardBase" }
            Blend SrcAlpha OneMinusSrcAlpha  // Alpha 混合模式
            ZWrite Off   // 关闭深度写入，防止透明物体遮挡错误
            Cull Back    // 剔除背面（也可以设置为 Off 让物体双面可见）

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata_t
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)  // 雾效支持
                float4 pos : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _Alpha;
            float4 _Color;

            v2f vert (appdata_t v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                UNITY_TRANSFER_FOG(o, o.pos);  // 计算雾效
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 texColor = tex2D(_MainTex, i.uv);
                float test = smoothstep(texColor.r, texColor.r + 0.1, 0.5);
                half4 finalColor = texColor * _Color;
                half4 mask = tex2D(_Alpha, i.uv);
                texColor.a *= mask.a;
                UNITY_APPLY_FOG(i.fogCoord, finalColor);  // 应用雾效
                return texColor;
            }
            ENDCG
        }
    }
}