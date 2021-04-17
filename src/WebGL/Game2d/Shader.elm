module WebGL.Game2d.Shader exposing
    ( vertNone, vertRect, vertImage, vertTriangle, vertTile, vertSprite
    , fragFill, fragCircle, fragNgon, fragImage, fragImageColor, fragTilemap
    , mesh, meshTriangle
    )

{-|


# Vertex Shaders

@docs vertNone, vertRect, vertImage, vertTriangle, vertTile, vertSprite


# Fragment Shaders

@docs fragFill, fragCircle, fragNgon, fragImage, fragImageColor, fragTilemap


# Mesh

@docs mesh, meshTriangle

-}

import Math.Vector2 exposing (Vec2, vec2)
import Math.Vector4 exposing (Vec4)
import WebGL exposing (Mesh, Shader)
import WebGL.Texture exposing (Texture)



-- Vertex Shaders


{-| -}
vertTriangle : Shader { a | i : Float } { b | uP : Vec2, uT : Vec4, z : Float, vert0 : Vec2, vert1 : Vec2, vert2 : Vec2 } {}
vertTriangle =
    --http://in2gpu.com/2014/11/24/creating-a-triangle-in-opengl-shader/
    -- 1 / (2 ^ 23 - 1)  = 0.000000119209304
    [glsl|
    precision highp float;
    attribute float i;
    uniform vec2 vert0;
    uniform vec2 vert1;
    uniform vec2 vert2;
    uniform vec4 uT;
    uniform vec2 uP;
    uniform float z;
    void main () {
     vec2 aP;
     if (i == 0.) {
        aP = vert0;
     } else if (i == 1.) {
        aP = vert1;
     } else if (i == 2.) {
        aP = vert2;
     }
     gl_Position = vec4(aP * mat2(uT) + uP, z  * -1.19209304e-7, 1.0);
    }
    |]


{-| -}
vertImage : Shader { a | aP : Vec2 } { b | uP : Vec2, uT : Vec4, z : Float } { uv : Vec2 }
vertImage =
    [glsl|
            precision highp float;
            attribute vec2 aP;
            uniform vec4 uT;
            uniform vec2 uP;
            uniform float z;
            varying vec2 uv;
            vec2 edgeFix = vec2(0.0000001, -0.0000001);
            void main () {
                uv = aP * .5 + 0.5 + edgeFix;
                gl_Position = vec4(aP * mat2(uT) + uP, z  * -1.19209304e-7, 1.0);
            }
        |]


{-| -}
vertNone : Shader { a | aP : Vec2 } { b | uP : Vec2, uT : Vec4, z : Float } {}
vertNone =
    [glsl|
        precision highp float;
        attribute vec2 aP;
        uniform vec4 uT;
        uniform vec2 uP;
        uniform float z;
        void main () {
            gl_Position = vec4(aP * mat2(uT) + uP, z * -1.19209304e-7, 1.0);
        }
    |]


{-| -}
vertRect : Shader { a | aP : Vec2 } { b | uP : Vec2, uT : Vec4, z : Float } { uv : Vec2 }
vertRect =
    [glsl|
            precision highp float;
            attribute vec2 aP;
            uniform vec4 uT;
            uniform vec2 uP;
            uniform float z;
            varying vec2 uv;
            vec2 edgeFix = vec2(0.0000001, -0.0000001);
            void main () {
                uv = aP + edgeFix;
                gl_Position = vec4(aP * mat2(uT) + uP, z  * -1.19209304e-7, 1.0);
            }
        |]


{-| -}
vertTile :
    Shader
        { a | aP : Vec2 }
        { b
            | uImgSize : Vec2
            , index : Float
            , spriteSize : Vec2
            , uP : Vec2
            , uT : Vec4
            , z : Float
        }
        { uv : Vec2 }
vertTile =
    [glsl|
            precision highp float;
            attribute vec2 aP;
            uniform vec4 uT;
            uniform vec2 uP;
            uniform float z;
            uniform float index;
            uniform vec2 spriteSize;
            uniform vec2 uImgSize;
            varying vec2 uv;
            vec2 edgeFix = vec2(0.0000001, -0.0000001);
            void main () {
                vec2 ratio = spriteSize / uImgSize;
                float row = (uImgSize.y / spriteSize.y - 1.0) - floor((index + 0.5) * ratio.x);
                float column = floor(mod((index + 0.5), uImgSize.x / spriteSize.x));
                vec2 offset = vec2(column, row) * ratio;
                uv = (aP * 0.5 + 0.5) * ratio + offset + edgeFix;
                gl_Position = vec4(aP * mat2(uT) + uP, z  * -1.19209304e-7, 1.0);
            }
        |]


{-| -}
vertSprite : Shader { a | aP : Vec2 } { b | uP : Vec2, uT : Vec4, uUV : Vec4, z : Float } { uv : Vec2 }
vertSprite =
    [glsl|
            precision highp float;
            attribute vec2 aP;
            uniform vec4 uT;
            uniform vec2 uP;
            varying vec2 uv;
            uniform vec4 uUV;
            uniform float z;
            vec2 edgeFix = vec2(0.0000001, -0.0000001);
            void main () {
                vec2 aP_ = aP * .5 + 0.5;
                uv = uUV.xy + (aP_ * uUV.zw) + edgeFix;
                gl_Position = vec4(aP * mat2(uT) + uP, z  * -1.19209304e-7, 1.0);
            }
        |]



--Fragment Shaders


{-| -}
fragImage : Shader a { b | uImg : Texture, uImgSize : Vec2, uA : Float } { uv : Vec2 }
fragImage =
    --(2i + 1)/(2N) Pixel perfect center
    [glsl|
        precision highp float;
        varying vec2 uv;
        uniform vec2 uImgSize;
        uniform sampler2D uImg;
        uniform float uA;
        void main () {
            vec2 pixel = (floor(uv * uImgSize) + 0.5) / uImgSize;
            gl_FragColor = texture2D(uImg, pixel);
            gl_FragColor.a *= uA;
            if(gl_FragColor.a <= 0.025) discard;
        }
    |]


{-| -}
fragImageColor : Shader a { b | color : Vec4, uImg : Texture, uImgSize : Vec2 } { uv : Vec2 }
fragImageColor =
    [glsl|
        precision highp float;
        varying vec2 uv;
        uniform vec2 uImgSize;
        uniform sampler2D uImg;
        uniform vec4 color;
        void main () {
            vec2 pixel = ((floor(uv * uImgSize) + 0.5) * 2.0 ) / uImgSize / 2.0;
            gl_FragColor = texture2D(uImg, pixel) * color;
            if(gl_FragColor.a <= 0.025) discard;
        }
    |]


{-| -}
fragFill : Shader a { b | color : Vec4 } {}
fragFill =
    [glsl|
        precision highp float;
        uniform vec4 color;
        void main () {
            gl_FragColor = color;
            if(gl_FragColor.a <= 0.025) discard;
        }
    |]


{-| -}
fragCircle : Shader a { b | color : Vec4 } { uv : Vec2 }
fragCircle =
    [glsl|
        precision highp float;
        uniform vec4 color;
        varying vec2 uv;
        void main () {
            gl_FragColor = color;
            gl_FragColor.a *= smoothstep(0.01,0.04,1.-length(uv));
            if(gl_FragColor.a <= 0.025) discard;
        }
    |]


{-| -}
fragNgon : Shader a { b | color : Vec4, n : Float } { uv : Vec2 }
fragNgon =
    --https://thebookofshaders.com/07/
    --https://thndl.com/square-shaped-shaders.html
    [glsl|
        precision highp float;
        uniform vec4 color;
        uniform float n;
        varying vec2 uv;
        void main () {
            float angle = 3.1415926535897932384626433832795 / n * 3.0;
            float a = atan(uv.x,uv.y) + angle;
            float b = 6.28319 / n;
            gl_FragColor = color;
            gl_FragColor.a -= smoothstep(0.5, 0.5001, cos(floor(.5 + a/b)*b-a)*length(uv));
            if(gl_FragColor.a <= 0.025) discard;
        }
    |]


{-| -}
fragTilemap : Shader a { b | uA : Float, uAtlas : Texture, uAtlasSize : Vec2, uLut : Texture, uLutSize : Vec2, uTileSize : Vec2 } { uv : Vec2 }
fragTilemap =
    --http://media.tojicode.com/webgl-samples/tilemap.html
    [glsl|
precision highp float;
varying vec2 uv;
uniform sampler2D uAtlas;
uniform sampler2D uLut;
uniform vec2 uAtlasSize;
uniform vec2 uLutSize;
uniform vec2 uTileSize;
uniform float uA;
float color2float(vec4 color) {
//    return color.a * 255.0 + color.b * 256.0 * 255.0 + color.g * 256.0 * 256.0 * 255.0 + color.r * 256.0 * 256.0 * 256.0 * 255.0;
    return color.a * 255.0 + color.b * 65280.0 + color.g * 16711680.0 + color.r * 4278190080.0;
    }
/**
 * Returns accurate MOD when arguments are approximate integers.
 */
float modI(float a,float b) {
    float m=a-floor((a+0.5)/b)*b;
    return floor(m+0.5);
}
void main () {
    vec2 point = floor(uv * uLutSize);
    vec2 offset = fract(uv * uLutSize);
    //(2i + 1)/(2N) Pixel center
    vec2 coordinate = (point + 0.5) / uLutSize;
    float index = color2float(texture2D(uLut, coordinate));
    if (index <= 0.0) discard;
    vec2 grid = uAtlasSize / uTileSize;
    // tile indexes in uAtlas starts from zero, but in lut zero is used for
    // "none" placeholder
    vec2 tile = vec2(modI((index - 1.), grid.x), int(index - 1.) / int(grid.x));
    // inverting reading botom to top
    tile.y = grid.y - tile.y - 1.;
    vec2 fragmentOffsetPx = floor(offset * uTileSize);
    //(2i + 1)/(2N) Pixel center
    vec2 pixel = (floor(tile * uTileSize + fragmentOffsetPx) + 0.5) / uAtlasSize;
    gl_FragColor = texture2D(uAtlas, pixel);
    gl_FragColor.a *= float(index != 0.0);
   if(gl_FragColor.a <= 0.025) discard;
}
    |]



---MESHES


{-| -}
meshTriangle : WebGL.Mesh { i : Float }
meshTriangle =
    WebGL.triangleStrip
        [ { i = 0 }
        , { i = 1 }
        , { i = 2 }
        ]


{-| -}
mesh : Mesh { aP : Vec2 }
mesh =
    WebGL.triangleStrip
        [ { aP = vec2 -1 -1 }
        , { aP = vec2 -1 1 }
        , { aP = vec2 1 -1 }
        , { aP = vec2 1 1 }
        ]
