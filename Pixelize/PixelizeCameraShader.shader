Shader "ore/PixelizeCameraShader" {
    /*
        Only on orthographics
     */
    Properties {
        _PixelColor ("Base (RGB)", 2D) = "white" {}
        _PixelDepth ("Base (RGB)", 2D) = "white" {}
        _NormalColor ("Base (RGB)", 2D) = "white" {}
        _NormalDepth ("Base (RGB)", 2D) = "white" {}
    }
    SubShader {
        Tags {
            "RenderType"="Opaque"
            "Queue"="Transparent"
        }
        LOD 200
        Pass {
            Name "Bullet"
            Cull Off
            ZTest Off
            Blend One Zero
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#include "UnityCG.cginc"

sampler2D _PixelColor;
sampler2D _PixelDepth;
sampler2D _NormalColor;
sampler2D _NormalDepth;
half4 _PixelColor_ST;
half4 _PixelDepth_ST;
half4 _NormalColor_ST;
half4 _NormalDepth_ST;

struct a2v {
    float4 vertex : POSITION;
    float4 color : COLOR;
    float2 uv : TEXCOORD0;
    float2 uv2 : TEXCOORD1;
};

struct v2f {
    float4 position : SV_POSITION;
    float4 color : COLOR;
    float2 uv : TEXCOORD0;
    float2 uv2 : TEXCOORD1;
};


v2f vert(a2v v) {
    v2f o;
    o.position = mul(UNITY_MATRIX_MVP, v.vertex);
    o.color = v.color;
    o.uv = TRANSFORM_TEX(v.uv, _PixelColor);
    o.uv2 = TRANSFORM_TEX(v.uv2, _NormalColor);
    return o;
}

fixed4 frag(v2f i) : COLOR {
    float pd = DECODE_EYEDEPTH(tex2D(_PixelDepth, i.uv));
    float nd = DECODE_EYEDEPTH(tex2D(_NormalDepth, i.uv2));
    if (pd < nd) {
        half4 pc = tex2D(_PixelColor, i.uv);
        pc *= 8.0;
        pc = floor(pc);
        pc *= 1.0/8.0;
        return pc;
    }
    return tex2D(_NormalColor, i.uv2);
}
ENDCG
        }
    }
    FallBack "Diffuse"
}
