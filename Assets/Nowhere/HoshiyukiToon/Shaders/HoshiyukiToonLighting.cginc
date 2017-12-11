/** ライティングに関するヘッダ.
 *
 * @date	2017/12/7
 */
#ifndef NWH_TOONLIT_INC
#define NWH_TOONLIT_INC
#include "HoshiyukiToonCommon.cginc"

/*
 分岐用キーワード
  - NWH_TOON_CUTOUT		- 定義時clip関数の使用、SurfaceOutput.Alphaに対して実行される
  - NWH_TOON_STANDARDGI - 定義時、通常のGIを使用する
  - CLIP_PROCESS(o)		- NWH_TOON_CUTOUTの実装部、o.Alphaに対してclip()を実行する
*/

/* --- Keyworlds --- */
	#ifdef NWH_TOON_CUTOUT
		#define CLIP_PROCESS(o) clip(o .Alpha);
	#else
		#define CLIP_PROCESS(o)
	#endif
/* --- end --- */


/* --- Variables --- */
	uniform sampler2D	_ToonTex;
	uniform fixed		_ToonFactor;
/* end */


/* --- Light functions --- */

	inline half3 GetRamp( half NdL )
	{
		NdL = NdL*0.5 + 0.5;
		return lerp( half3(1,1,1), tex2D(_ToonTex,float2(NdL,NdL)).rgb, _ToonFactor );
	}


	/** ライティング関数.
	 *
	 */
	inline half4 LightingToonRamp(SurfaceOutputStandardSpecular s, half3 lightDir, UnityGI gi)
	{
		s.Normal = normalize( s.Normal );
		half3	ramp = GetRamp( dot( s.Normal, gi.light.dir ) );


		half4 c;
		c.rgb = s.Albedo * gi.light.color * ramp * NWH_TOON_FWDLIGHT_INTENSITY;
		c.rgb	+= gi.indirect.diffuse*s.Albedo;
		c.rgb	+= gi.indirect.specular*s.Specular;
		c.a		= s.Alpha;
		return c;
	}

	/** グローバルイルミネーション関数.
	 *
	 */
	inline void LightingToonRamp_GI(inout SurfaceOutputStandardSpecular s, UnityGIInput data, inout UnityGI gi )
	{
		#ifdef NWH_TOON_STANDARDGI
			LightingStandardSpecular_GI( s, data, gi );
		#else
			Unity_GlossyEnvironmentData g	= UnityGlossyEnvironmentSetup( s.Smoothness, data.worldViewDir, s.Normal, s.Specular);
			gi								= ToonGI_Base( data, s.Occlusion, s.Normal );
			gi.indirect.specular			= UnityGI_IndirectSpecular( data, s.Occlusion, g );
		#endif
	}


	/** ライティング関数.
	 *
	 */
	inline half4 LightingToonRampMetallic( SurfaceOutputStandard s, half3 lightDir, UnityGI gi )
	{
		s.Normal = normalize( s.Normal );
		half3	ramp = GetRamp( dot( s.Normal, gi.light.dir ) );

		half4	c;
		half	oneMinusReflectivity;
		half3	specColor;
		s.Albedo = DiffuseAndSpecularFromMetallic( s.Albedo, s.Metallic, specColor, oneMinusReflectivity );

		c.rgb = s.Albedo * gi.light.color * ramp * NWH_TOON_FWDLIGHT_INTENSITY;
		c.rgb	+= gi.indirect.diffuse*s.Albedo;
		c.rgb	+= gi.indirect.specular*specColor;
		c.a		= s.Alpha;
		return c;
	}

	/** グローバルイルミネーション関数.
	*
	*/
	inline void LightingToonRampMetallic_GI( inout SurfaceOutputStandard s, UnityGIInput data, inout UnityGI gi )
	{
		#ifdef NWH_TOON_STANDARDGI
			LightingStandard_GI( s, data, gi );
		#else
			Unity_GlossyEnvironmentData g	= UnityGlossyEnvironmentSetup( s.Smoothness, data.worldViewDir, s.Normal, lerp( unity_ColorSpaceDielectricSpec.rgb, s.Albedo, s.Metallic ));
			gi								= ToonGI_Base( data, s.Occlusion, s.Normal );
			gi.indirect.specular			= UnityGI_IndirectSpecular( data, s.Occlusion, g );
		#endif
	}
/* end */
#endif