Shader "HoshiyukiToon/Custom/Blend Test" {
	Properties {
		// Your own variables
		_MainTex	("Blend Texture", 2D) ="white"{}
		_Color		("Color", Color) = (1,1,1,1)
		_Color2		("Color 2", Color ) = (0,0,1,1)

		// REQUIRED : Lit variables
		_ToonTex("Directional Ramp", 2D) = "white"{}
		_ToonPointLightTex("Point Ramp", 2D)="white"{}
		_ToonFactor( "Ramp Factor", Range( 0,1 ) ) = 1
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
			// REQUIRED : Minimum shader options
			#pragma surface surf ToonRamp fullforwardshadows addshadow
			#pragma target 3.0
			#include <Assets/Nowhere/HoshiyukiToon/Shaders/HoshiyukiToonLighting.cginc>


			// OPTIONAL : if this keyword is defined, the ramp texture of point light is enabled.
			#define HTS_USE_POINTLIGHTRAMP


			struct Input {
				float2 uv_MainTex;
			};

			sampler2D	_MainTex;
			fixed4		_Color;
			fixed4		_Color2;

			/** Your own surface shader
			 */
			void surf (Input IN, inout SurfaceOutputStandardSpecular o) {
				fixed	t		= sin(_Time * 10)*0.5 + 0.5;
				fixed	factor	= (tex2D( _MainTex, IN.uv_MainTex ).r > t) ? 0 : 1;
				fixed4	ret		= lerp(_Color, _Color2, factor);

				o.Albedo.rgb	= ret.rgb;
				o.Alpha			= 1;
			}
		ENDCG

		// OPTIONAL : Shadowcaster for two sided face
		// UsePass "HoshiyukiToon/Lit/SHADOWCASTER"
	}
	FallBack "Diffuse"
}
