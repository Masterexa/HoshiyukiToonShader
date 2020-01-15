/** 
 * @date 2018/5/24
 */
#ifndef NWH_HTS_SURFACE_LIT_BASE_INC
#define NWH_HTS_SURFACE_LIT_BASE_INC

/* includes */
#include "HoshiyukiToonLighting.cginc"

/* properties */
fixed		_Cutoff;
sampler2D	_MainTex;
fixed4		_Color;
fixed		_OcclusionStrength;
sampler2D	_OcclusionMap;
half3		_EmissionColor;
sampler2D	_EmissionMap;

fixed       _Glossiness;
fixed       _Metallic;
fixed       _SpecularFactor;
sampler2D   _MetallicGlossMap;



/* typedefs */
	struct Input {
		float2 uv_MainTex;
	};


inline half4 SampleMOXSMap(float2 uv)
{
    half4 moxs  = tex2D(_MetallicGlossMap, uv) * half4(_Metallic,0,0,_Glossiness);
    moxs.g      = lerp(1, tex2D(_OcclusionMap, uv).g, _OcclusionStrength);
    return moxs;
}


/* Shader kernels */
	/** Surface shader.
	 *
	 */
	void surfLitBase( Input IN, inout SurfaceOutputStandardSpecular o ) {
		fixed4	c		= tex2D(_MainTex, IN.uv_MainTex) * _Color;
		half3	emit	= tex2D(_EmissionMap, IN.uv_MainTex).rgb * _EmissionColor;
        half4   moxs    = SampleMOXSMap(IN.uv_MainTex);

        o.Specular.r    = moxs.r;
        o.Specular.g    = _SpecularFactor;
        o.Smoothness    = moxs.a;
		o.Albedo		= c.rgb;
		o.Emission		= emit;
		o.Occlusion		= moxs.g;
		o.Alpha			= c.a;

		#ifdef NWH_TOON_CUTOUT
			clip(c.a-_Cutoff);
		#endif
	}

#endif