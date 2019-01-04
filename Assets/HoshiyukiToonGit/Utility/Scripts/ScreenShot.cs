using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;
using UnityEngine;

namespace NowhereUnity.Utility{

    public static class ScreenShot {
        #region Class
            #region Methods
                public static void TakeCameraImage(Camera camera, Texture2D destination) {
                    var rt      = new RenderTexture(destination.width, destination.height, 24);
                    var camRt   = camera.targetTexture;
                    
                    camera.targetTexture    = rt;
                    camera.Render();
                    RenderTexture.active    = rt;
                    destination.ReadPixels(new Rect(0, 0, destination.width, destination.height), 0, 0);

                    camera.targetTexture    = camRt;
                    RenderTexture.active    = null;
                    if( Application.isPlaying )
                    {
                        UnityEngine.Object.Destroy(rt);
                    }
                    else
                    {
                        UnityEngine.Object.DestroyImmediate(rt);
                    }
                }
            #endregion
        #endregion
    }
}
