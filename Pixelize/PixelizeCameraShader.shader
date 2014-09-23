Shader "ore/PixelizeCameraShader" {
    Properties {
        _ColorReductionLevel ("Color Reduction Level", Vector) = (1, 1, 0, 0)
        _PixelColor ("Pixel Color", 2D) = "white" {}
        _PixelDepth ("Pixel Depth", 2D) = "white" {}
        _NormalColor ("Normal Color", 2D) = "white" {}
        _NormalDepth ("Normal Depth", 2D) = "white" {}
        _Grid ("Grid", Vector) = (4, 4, 1, 1)
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
half4 _ColorReductionLevel;
half4 _PixelColor_ST;
half4 _PixelDepth_ST;
half4 _NormalColor_ST;
half4 _NormalDepth_ST;
half4 _Grid;

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
    float pd = DECODE_EYEDEPTH(tex2D(_PixelDepth, i.uv).x);
    float nd = DECODE_EYEDEPTH(tex2D(_NormalDepth, i.uv2).x);
    if (pd < nd) {
        half4 pc = tex2D(_PixelColor, i.uv);
        pc *= _ColorReductionLevel.x;
        pc = floor(pc + 0.5);
        pc *= _ColorReductionLevel.y;
        int u = i.uv.x * _ScreenParams.x;
        int v = i.uv.y * _ScreenParams.y;

        if (u % (int)_Grid.x == 0 || v % (int)_Grid.y == 0) {
            return pc * 0.5f;
        } else {
            return pc * 1.5f;
        }
    }
    return tex2D(_NormalColor, i.uv2);// * 0.5f;
}
ENDCG
        }
    }
    FallBack "Diffuse"
}
