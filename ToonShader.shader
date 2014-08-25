Shader "ore/ToonShader" {
    Properties {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _SpecTex ("Specular Map", 2D) = "white" {}
        _ShadeLevel ("Shade Level", Float) = 0.5
        _ShadeColor ("Shade Color", Color) = (0.5, 0.5, 0.5, 1)
        _SilhouetteWidth ("Silhouette Width", Float) = 0.02
        _SilhouetteColor ("Silhouette Color", Color) = (0,0,0,1)
        _Shininess ("Shininess", Float) = 10
        //_ToonTex ("Toon", 2D) = "white" {}
    }
    SubShader {
        Tags { "RenderType"="Opaque" }
        Pass {
            Tags {
                "LightMode"="ForwardBase"
            }
            Name "Outer"
            ZWrite On
            Cull Front
            //LOD 200
CGPROGRAM
#pragma fragmentoption ARB_precision_hint_fastest
#pragma vertex vert
#pragma fragment frag
#include "UnityCG.cginc"

    half _SilhouetteWidth;
    half4 _SilhouetteColor;

// モバイル用のシンプルなやつ
struct appdata_mobile {
    float4 vertex : POSITION;
    fixed3 normal : NORMAL;
    fixed4 color : COLOR;
};
struct v2f {
    float4 pos : SV_POSITION;
};

v2f vert(appdata_mobile v) {
    v2f o;
    float4 posWorld = mul(_Object2World, v.vertex);
    float3 camvec = (posWorld.xyz - _WorldSpaceCameraPos);
    //float3 camvec = (_WorldSpaceCameraPos - posWorld.xyz);
    float camdist = length(camvec);
    camvec = normalize(camvec);
    float width = _SilhouetteWidth;// * v.color.g; // 輪郭線の太さ
    float scale = max(width, (4.0 * width) * (1.0 - 1.0 / camdist)) * v.color.a;
    float4 pos = v.vertex + float4(v.normal * scale, 0.0);
    pos = mul(UNITY_MATRIX_MV, pos);
    pos += float4(camvec * ((1.0 - v.color.b) * 0.02), 0.0);
    //pos += float4(camvec * (v.color.b * 0.02), 0.0);
    o.pos = mul(UNITY_MATRIX_P, pos);
    return o;
}
half4 frag(v2f i) : COLOR {
    return float4(_SilhouetteColor.xyz, 1);
}
ENDCG
        }
        Pass {
            Tags { "LightMode"="ForwardBase" }
            Name "Inner"
            ZWrite On
            Cull back
            Lighting On
            //LOD 200
CGPROGRAM
#pragma fragmentoption ARB_precision_hint_fastest
#pragma vertex vert
#pragma fragment frag
#include "UnityCG.cginc"
#include "Lighting.cginc"

    sampler2D _MainTex;
    half4 _MainTex_ST;
    sampler2D _SpecTex;
    half _ShadeLevel;
    half4 _ShadeColor;
    //sampler2D _ToonTex;
    //half4 _ToonTex_ST;
    //half4 _Color;
    //half4 _SpecColor;
    half _Shininess;
// モバイル用のシンプルなやつ
struct appdata_mobile {
    float4 vertex : POSITION;
    fixed3 normal : NORMAL;
    fixed4 color : COLOR;
    half4 texcoord : TEXCOORD0;
};
struct v2f {
    float4 pos : SV_POSITION;
    float4 posWorld : TEXCOORD0;
    half3 normalDir : TEXCOORD1;
    //fixed4 vertexLighting : COLOR0;
    fixed4 color : COLOR0;
    half2 uv : TEXCOORD2;
};

v2f vert(appdata_mobile v) {
#if 0
    v2f o;
    o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
    o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
    o.posWorld = mul(_Object2World, v.vertex);
    //o.normalDir = v.normal;
    //o.normalDir = normalize(mul(UNITY_MATRIX_MV, float4(v.normal, 0)));
    //o.normalDir = normalize(mul(_World2Object, float4(v.normal, 0)));
    o.normalDir = normalize(half3(mul(float4(v.normal, 0), _World2Object)));
    float3 vertexLighting = float3(0.0, 0.0, 0.0);
    for (int index = 0; index < 4; index++) {
        float4 lightPosition = float4(unity_4LightPosX0[index], unity_4LightPosY0[index], unity_4LightPosZ0[index], 1.0);
        float3 vertexToLightSource = float3(lightPosition - o.posWorld);
        float3 lightDirection = normalize(vertexToLightSource);
        float squaredDistance = dot(vertexToLightSource, vertexToLightSource);
        float attenuation = 1.0 / (1.0 + unity_4LightAtten0[index] * squaredDistance);
        float3 diffuseReflection = 
            attenuation * float3(unity_LightColor[index]) 
            //* float3(_Color) * max(0.0, dot(v.normal, lightDirection));
            * max(0.0, dot(o.normalDir, lightDirection));

        vertexLighting = vertexLighting + diffuseReflection;
    }
    o.vertexLighting = float4(vertexLighting, 1);
    return o;
#else
    v2f o;
    o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
    o.posWorld = mul(_Object2World, v.vertex);
    o.normalDir = normalize(half3(mul(float4(v.normal, 0), _World2Object)));
    //o.normalDir = normalize(mul(float4(v.normal, 0), _World2Object));
    o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
    //o.vertexLighting = half4(0, 0, 0, 0);
    o.color = v.color;
    //o.color = half4(0.5, 0, 0, 0);
    return o;
#endif
}
half4 frag(v2f i) : COLOR {
#if 1
    float3 normalDirection = normalize(i.normalDir);
    float3 viewDirection = normalize(
        _WorldSpaceCameraPos - float3(i.posWorld));
    float3 lightDirection;
    float attenuation;

    if (0.0 == _WorldSpaceLightPos0.w) { // directional light?
        attenuation = 1.0; // no attenuation
        lightDirection = normalize(float3(_WorldSpaceLightPos0));
    } else { // point or spot light
        float3 vertexToLightSource = float3(_WorldSpaceLightPos0 - i.posWorld);
        float distance = length(vertexToLightSource);
        attenuation = 1.0 / distance; // linear attenuation 
        lightDirection = normalize(vertexToLightSource);
    }

    float ambientLighting = length(float3(UNITY_LIGHTMODEL_AMBIENT));
    float diffuseReflection = attenuation * max(0.0, dot(normalDirection, lightDirection));
    float specularReflection;
    if (dot(normalDirection, lightDirection) < 0.0) {
        // light source on the wrong side?
        specularReflection = 0.0;
        // no specular reflection
    } else { // light source on the right side
        specularReflection = attenuation * pow(max(0.0, dot(reflect(-lightDirection, normalDirection), viewDirection)), _Shininess);
    }
    float lightingEnergy = /*length(i.vertexLighting) +*/ ambientLighting + diffuseReflection;// + specularReflection;
    fixed4 texel = tex2D(_MainTex, i.uv);
    fixed4 spec = tex2D(_SpecTex, i.uv);
    if (specularReflection * spec.x > 0.8) {
        return texel * (lightingEnergy + specularReflection) * _LightColor0;// * _Color;
    } else
    if (lightingEnergy * i.color.r < _ShadeLevel) {
        return texel * half4(_ShadeColor.xyz, 1.0) * _LightColor0;// * _Color;
    }
    return texel * _LightColor0;// * _Color;




    //if (length(specularReflection) > 0.9) {
    //    return float4(i.vertexLighting + ambientLighting + diffuseReflection + specularReflection, 1.0) * texel;
    //}
    //return float4(i.vertexLighting + ambientLighting + diffuseReflection, 1.0) * texel;
#else
    float3 normalDirection = normalize(i.normalDir);
    float3 viewDirection = normalize(
        _WorldSpaceCameraPos - float3(i.posWorld));
    float3 lightDirection;
    float attenuation;

    if (0.0 == _WorldSpaceLightPos0.w) { // directional light?
        attenuation = 1.0; // no attenuation
        lightDirection = normalize(float3(_WorldSpaceLightPos0));
    } else { // point or spot light
        float3 vertexToLightSource = float3(_WorldSpaceLightPos0 - i.posWorld);
        float distance = length(vertexToLightSource);
        attenuation = 1.0 / distance; // linear attenuation 
        lightDirection = normalize(vertexToLightSource);
    }

    float3 ambientLighting = float3(UNITY_LIGHTMODEL_AMBIENT) * float3(_Color);

    float3 diffuseReflection = attenuation * float3(_LightColor0) * float3(_Color) * max(0.0, dot(normalDirection, lightDirection));

    float3 specularReflection;
    if (dot(normalDirection, lightDirection) < 0.0) {
        // light source on the wrong side?
        specularReflection = float3(0.0, 0.0, 0.0);
        // no specular reflection
    } else { // light source on the right side
        specularReflection = attenuation * float3(_LightColor0) * float3(_SpecColor) * pow(max(0.0, dot(reflect(-lightDirection, normalDirection), viewDirection)), _Shininess);
    }

    fixed4 texel = tex2D(_MainTex, i.uv);

    if (length(specularReflection) > 0.8) {
        return float4(i.vertexLighting + ambientLighting + diffuseReflection + specularReflection, 1.0) * texel;
    }
    return float4(i.vertexLighting + ambientLighting + diffuseReflection, 1.0) * texel;
#endif
}
ENDCG
        }
    }
    FallBack "Diffuse"
}
