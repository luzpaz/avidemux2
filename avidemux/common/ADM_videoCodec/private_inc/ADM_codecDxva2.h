/**
        \file FFDXVA2
 *      \brief wrapper around ffmpeg wrapper around DXVA2
 */


#include <BVector.h>
#include "ADM_threads.h"

#define ADM_DXVA2_BUFFER 24
#define ADM_MAX_SURFACE 24

typedef struct surface_info 
{
    int used;
    uint64_t age;
} surface_info;

/**
 * \class decoderFFDXVA2
 */
class decoderFFDXVA2:public ADM_acceleratedDecoderFF
{
protected:
protected:
                    bool        alive;
                    LPDIRECT3DSURFACE9          surfaces[ADM_MAX_SURFACE];
                    surface_info                surface_infos[ADM_MAX_SURFACE];
                    uint32_t                    num_surfaces;
                    uint64_t                    surface_age;

protected:
                    bool        initDXVA2Context();
public:                    
//                    bool        markSurfaceUsed(ADM_vaSurface *s);
                    //bool        markSurfaceUnused(ADM_vaSurface *s);
public:     // Callbacks
                    //int         getBuffer(AVCodecContext *avctx, AVFrame *pic);
                    //void        releaseBuffer(ADM_vaSurface *vaSurface);
                    bool        initFail(void) {alive=false;return true;}
public:
    virtual         bool        uncompress (ADMCompressedImage * in, ADMImage * out);
    virtual const   char        *getName(void)        {return "DXVA2";}
                    int         getBuffer(AVCodecContext *avctx, AVFrame *pic);
                    bool        releaseBuffer(uint8_t *data);
                    
public:
            // public API
                                decoderFFDXVA2 (AVCodecContext *avctx,decoderFF *parent);
                                ~decoderFFDXVA2();
};