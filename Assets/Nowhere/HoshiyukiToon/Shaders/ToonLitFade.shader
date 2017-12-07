/** 半透明のシェード.
 *
 * @date	2017/12/7
 */
Shader "HoshiyukiToon/LitFade" {
	Properties {
		// Lit
		_Color		("Color", Color) = (1,1,1,1)
		_MainTex	("Albedo (RGB)", 2D) = "white" {}
		_ToonTex	("Ramp Texture", 2D) = "white"{}
		_ToonFactor	("Ramp Factor", Range( 0,1 ) ) = 1
		
		// Lit Options
		[ToggleOff]								_UseStandardGI("Use Standard GI", Float) = 0
		[Enum(UnityEngine.Rendering.CullMode)]	_Cull("Cull Mode", Float ) = 2
	}
	SubShader{
		Tags { "RenderType" = "Opaque" }
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

			struct Input {
				float2 uv_MainTex;
			};


			/** サーフェイスシェーダー.
			 *
			 */
			void surf( Input IN, inout SurfaceOutputStandardSpecular o ) {
				fixed4 c		= tex2D( _MainTex, IN.uv_MainTex ) * _Color;
				o.Albedo		= c.rgb;
				o.Alpha			= c.a;
				CLIP_PROCESS(o)
			}
		ENDCG

		UsePass "HoshiyukiToon/Lit/SHADOWCASTER"
	}
	FallBack "Diffuse"
	CustomEditor "NowhereUnityEditor.Rendering.HoshiyukiToonEditor"
}
