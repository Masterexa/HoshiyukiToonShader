/** ライティングに関するヘッダ.
 *
 * @date	2017/12/7
 */
#ifndef NWH_TOONLIT_INC
#define NWH_TOONLIT_INC
#include "HoshiyukiToonCommon.cginc"
#include "UnityStandardBRDF.cginc"

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
	uniform sampler2D	_ToonPointLightTex;
	uniform fixed		_ToonFactor;
/* end */

struct HTSSurfaceParam
{
    fixed4  baseColor;
    fixed3  specularColor;
    fixed   specular;
    fixed   roughness;
    fixed   metallic;
    fixed   specularTint;
    fixed   sheen;
    fixed   sheenTint;
};

struct HTSLightingIn
{
    UnityGI gi;
    half3   L;
    half3   V;
    half3   N;
};


/* --- Light functions --- */

	inline half3 getToonRamp( half NdL )
	{
		NdL = NdL*0.5 + 0.5;

	#if defined(HTS_USE_POINTLIGHTRAMP) && !defined(USING_DIRECTIONAL_LIGHT)
		sampler2D toon = _ToonPointLightTex;
	#else
		sampler2D toon = _ToonTex;
	#endif

		return lerp( half3(1,1,1), tex2D(toon,float2(NdL,NdL)).rgb, _ToonFactor );
	}

	inline half4 NWH_HTS_Lighting( half3 diffuse, half3 specular, half oneMinusReflectivity, half smoothness, half3 N, half3 V, UnityLight light, UnityIndirect gi ) {

		half3 ramp = getToonRamp( dot( N, light.dir ) );
		half4 c;

		c.rgb	= diffuse*ramp*light.color * NWH_TOON_FWDLIGHT_INTENSITY;
		c.rgb	+= gi.diffuse*diffuse;
		c.rgb	+= gi.specular*specular;
		c.a		= 1;
		return c;
	}

    inline half4 hts_PBS_DirectMetallic(in HTSSurfaceParam param, in HTSLightingIn light)
    {
        return half4(0,0,0,0);
    }



	/** ライティング関数.
	 *
	 */
	inline half4 LightingToonRamp(SurfaceOutputStandardSpecular s, half3 lightDir, UnityGI gi)
	{
		s.Normal = normalize( s.Normal );
		half3	ramp = getToonRamp( dot( s.Normal, gi.light.dir ) );

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
			gi = HoshiyukiToonGI( data, s.Occlusion, s.Normal, g );
		#endif
	}


	/** ライティング関数.
	 *
	 */
	inline half4 LightingToonRampMetallic( SurfaceOutputStandard s, half3 viewDir, UnityGI gi )
	{
		s.Normal = normalize( s.Normal );
		half3	ramp = getToonRamp( dot( s.Normal, gi.light.dir ) );

        half4 c = half4(0,0,0,0);
		half	oneMinusReflectivity;
		half3	specColor;
		s.Albedo = DiffuseAndSpecularFromMetallic( s.Albedo, s.Metallic, specColor, oneMinusReflectivity );

        half m = saturate(1 - dot(viewDir, s.Normal));
        half f = lerp(m * m * m * m * m, 1, s.Metallic);

        half NV = dot(s.Normal, viewDir);
        half R  = reflect(viewDir, s.Normal);

        half2 rlPow4AndFresnelTerm = Pow4(half2(dot(R, gi.light.dir), 1 - NV)); // use R.L instead of N.H to save couple of instructions
        half rlPow4 = rlPow4AndFresnelTerm.x; // power exponent must match kHorizontalWarpExp in NHxRoughness() function in GeneratedTextures.cpp
        half fresnelTerm = rlPow4AndFresnelTerm.y;

        half grazing = saturate(s.Smoothness + (1 - oneMinusReflectivity));

		c.rgb = s.Albedo * gi.light.color * ramp * NWH_TOON_FWDLIGHT_INTENSITY;
		c.rgb += gi.indirect.diffuse*s.Albedo;
        c.rgb += gi.indirect.specular * lerp(specColor, 1, fresnelTerm);
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
			gi = HoshiyukiToonGI( data, s.Occlusion, s.Normal, g );
		#endif
	}


	/** ライティング関数.
	 *
	 */
    inline half4 LightingToonRampMetallic2(SurfaceOutputStandardSpecular s, half3 viewDir, UnityGI gi)
    {
        s.Normal = normalize(s.Normal);
        half3 ramp = getToonRamp(dot(s.Normal, gi.light.dir));

        half4 c = half4(0, 0, 0, 0);
        half oneMinusReflectivity;
        half3 specColor;
        s.Albedo = DiffuseAndSpecularFromMetallic(s.Albedo, s.Specular.r, specColor, oneMinusReflectivity);

        half NV = dot(s.Normal, viewDir);
        half R = reflect(viewDir, s.Normal);

        half2 rlPow4AndFresnelTerm = Pow4(half2(dot(R, gi.light.dir), 1 - NV)); // use R.L instead of N.H to save couple of instructions
        half rlPow4 = rlPow4AndFresnelTerm.x; // power exponent must match kHorizontalWarpExp in NHxRoughness() function in GeneratedTextures.cpp
        half fresnelTerm = rlPow4AndFresnelTerm.y;

        half grazing = saturate(s.Smoothness + (1 - oneMinusReflectivity));

        c.rgb = s.Albedo * gi.light.color * ramp * NWH_TOON_FWDLIGHT_INTENSITY;
        c.rgb += gi.indirect.diffuse * s.Albedo;
        c.rgb += gi.indirect.specular * (lerp(specColor, grazing, fresnelTerm) * s.Specular.g);
        c.a = s.Alpha;
        return c;
    }

	    /** グローバルイルミネーション関数.
	    *
	    */
        inline void LightingToonRampMetallic2_GI(inout SurfaceOutputStandardSpecular s, UnityGIInput data, inout UnityGI gi)
        {
        #ifdef NWH_TOON_STANDARDGI
            SurfaceOutputStandard sm;
            sm.Albedo       = s.Albedo;
            sm.Metallic     = s.Specular.r;
            sm.Smoothness   = s.Smoothness;
            sm.Occlusion    = s.Occlusion;
            sm.Emission     = s.Emission;
            sm.Normal       = s.Normal;

		    LightingStandard_GI( sm, data, gi );
        #else
            Unity_GlossyEnvironmentData g = UnityGlossyEnvironmentSetup(s.Smoothness, data.worldViewDir, s.Normal, lerp(unity_ColorSpaceDielectricSpec.rgb, s.Albedo, s.Specular.r));
            gi = HoshiyukiToonGI(data, s.Occlusion, s.Normal, g);
        #endif
        }
/* end */
#endif