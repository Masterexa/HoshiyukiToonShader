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
	/** ライティング関数.
	 *
	 */
	inline half4 LightingToonRamp(SurfaceOutputStandardSpecular s, half3 lightDir, UnityGI gi)
	{
		s.Normal = normalize( s.Normal );
		half d = dot( s.Normal, gi.light.dir)*0.5 + 0.5;
		half3 ramp = tex2D( _ToonTex, float2(d, d) ).rgb;
		ramp = lerp( half3(1, 1, 1), ramp, _ToonFactor );

		half4 c;
		c.rgb = s.Albedo * gi.light.color * ramp * NWH_TOON_FWDLIGHT_INTENSITY;
		c.rgb  += gi.indirect.diffuse * s.Albedo;
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
			
			gi.light.color					*= data.atten;
			Unity_GlossyEnvironmentData g	= UnityGlossyEnvironmentSetup( s.Smoothness, data.worldViewDir, s.Normal, s.Specular);
			gi.indirect.diffuse				= ShadeToonSHPerPixel( s.Normal, half3(0,0,0), data.worldPos );
			gi.indirect.specular			= UnityGI_IndirectSpecular( data, s.Occlusion, g );
		#endif
	}
/* end */
#endif