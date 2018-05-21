#ifndef NWH_HTS_OUTLINE_INC
#define NWH_HTS_OUTLINE_INC

/* includes */
#include "UnityCG.cginc"


inline float4 HTS_expandVertexOutline(float size, half3 projNormal, float4 projPosition) {

	float fov = atan(1 / unity_CameraProjection._m11) * 2;

	projPosition.xy += projNormal.xy * UNITY_Z_0_FAR_FROM_CLIPSPACE(projPosition.z) * size;
	return projPosition;
}



#endif