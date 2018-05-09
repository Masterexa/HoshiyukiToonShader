/** 半透明のシェード.
 *
 * @date	2017/12/7
 */
Shader "HoshiyukiToon/LitFade" {
	Properties {
		// Lit
		_Color		("Color", Color) = (0.5859,0.5859,0.5859,1)
		_MainTex	("Albedo (RGB)", 2D) = "white" {}
		_ToonTex	( "Ramp Texture", 2D ) = "white"{}
		_ToonFactor	( "Ramp Factor", Range( 0,1 ) ) = 1
		// Occlusion
		_OcclusionStrength	( "Occlusion Strength", Range( 0,1 ) )=0
		_OcclusionMap		( "Occlusion Map", 2D )="white"{}
		// Emission
		_EmissionColor	( "Color", Color ) = (0,0,0)
		_EmissionMap	( "Emission", 2D ) = "white"{}
		
		// Lit Options
		[ToggleOff]								_UseStandardGI("Use Standard GI", Float) = 0
		[Enum(UnityEngine.Rendering.CullMode)]	_Cull("Cull Mode", Float ) = 2
	}
	SubShader{
		Tags { "RenderType" = "Opaque" "Queue"="Transparent" }
		Cull [_Cull]
		LOD 200

		CGPROGRAM
			#pragma multi_compile _ NWH_TOON_CUTOUT
			#pragma multi_compile _ NWH_TOON_STANDARDGI
			#pragma surface surf ToonRamp fullforwardshadows alpha:fade
			#pragma lighting ToonRamp exclude_path:prepass
			#pragma target 3.0
			#include "HoshiyukiToonLighting.cginc"

			sampler2D	_MainTex;
			fixed4		_Color;
			fixed		_OcclusionStrength;
			sampler2D	_OcclusionMap;

			struct Input {
				float2 uv_MainTex;
			};


			/** サーフェイスシェーダー.
			 *
			 */
			void surf( Input IN, inout SurfaceOutputStandardSpecular o ) {
				fixed4	c		= tex2D( _MainTex, IN.uv_MainTex ) * _Color;
				half	oc		= lerp( 1, tex2D( _OcclusionMap, IN.uv_MainTex ).r, _OcclusionStrength );
				o.Albedo		= c.rgb;
				o.Occlusion		= oc;
				o.Alpha			= c.a;
				clip(o.Alpha);
			}
		ENDCG

		UsePass "HoshiyukiToon/Lit/SHADOWCASTER"
	}
	FallBack "Diffuse"
	CustomEditor "NowhereUnityEditor.Rendering.HoshiyukiToonEditor"
}
