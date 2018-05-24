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



/* typedefs */
	struct Input {
		float2 uv_MainTex;
	};



/* kernels */
	/** Surface shader.
	 *
	 */
	void surfLitBase( Input IN, inout SurfaceOutputStandardSpecular o ) {
		fixed4	c		= tex2D(_MainTex, IN.uv_MainTex) * _Color;
		half3	emit	= tex2D(_EmissionMap, IN.uv_MainTex).rgb * _EmissionColor;
		half	oc		= lerp(1, tex2D(_OcclusionMap, IN.uv_MainTex).g, _OcclusionStrength);

		o.Albedo		= c.rgb;
		o.Emission		= emit;
		o.Occlusion		= oc;
		o.Alpha			= c.a;

		#ifdef NWH_TOON_CUTOUT
			clip(c.a-_Cutoff);
		#endif
	}

#endif