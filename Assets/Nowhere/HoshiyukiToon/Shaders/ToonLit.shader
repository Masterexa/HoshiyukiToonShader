/**	トゥーンシェード.
 *
 * @date	2017/12/7
 */
Shader "HoshiyukiToon/Lit" {
	Properties {
		// Lit
		_Color					("Color", Color) = (1,1,1,1)
		_MainTex				("Albedo (RGB)", 2D) = "white" {}
		_Cutoff					("Clip Threshold", Range(0,1)) = 0.1
		// Metallic and Smoothness
		_Glossiness				("Smoothness", Range(0,1))=0.5
		[Gamma]_Metallic		("Metallic", Range(0,1))=0.0
		[Gamma]_SpecularFactor	("Specular", Range(0,1))=0.0
		_MetallicGlossMap		("Metallic", 2D)="white"{}
		// Toon
		_ToonTex				("Ramp Texture", 2D) = "white"{}
		_ToonPointLightTex		("Point Light Ramp Texture", 2D) = "white"{}
		_ToonFactor				("Ramp Factor", Range( 0,1 ) ) = 1
		// Occlusion
		_OcclusionStrength	("Occlusion Strength", Range(0,1))=0
		_OcclusionMap		("Occlusion Map", 2D)="white"{}
		// Emission
		_EmissionColor		("Color", Color) = (0,0,0)
		_EmissionMap		("Emission", 2D) = "white"{}

		// Lit Options
		[ToggleOff]								_UseStandardGI("Use Standard GI", Float) = 0
		[ToggleOff]								_BlendOcclusionToAlbedo("Blend Occlusion to Albedo", Float) = 0
		[Enum(UnityEngine.Rendering.CullMode)]	_Cull("Cull Mode", Float ) = 2
		[HideInInspector]						_Blend("Mode", Float) = 0
	}
	SubShader{
		Tags { "RenderType" = "Opaque" }
		Cull [_Cull]
		LOD 200

		CGPROGRAM
			#pragma multi_compile _ NWH_TOON_CUTOUT
			#pragma multi_compile _ NWH_TOON_STANDARDGI
			#pragma multi_compile _ HTS_BLEND_OCCLUSION_TO_ALBEDO
			#pragma surface surfLitBase ToonRampMetallic2 fullforwardshadows addshadow
			#pragma target 3.0
			#define HTS_USE_POINTLIGHTRAMP

			#include "HoshiyukiToonSurfaceLitBase.cginc"
		ENDCG


		Pass 
        {
			Name "SHADOWCASTER"
            Tags {"LightMode"="ShadowCaster"}
            Cull Off
 
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"
 
            struct v2f {
                V2F_SHADOW_CASTER;
            };
 
            v2f vert(appdata_base v)
            {
                v2f o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }
 
            float4 frag(v2f i) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
	}
	FallBack "Diffuse"
	CustomEditor "HoshiyukiToonShaderEditor.SurfaceShaderInspector"
}
