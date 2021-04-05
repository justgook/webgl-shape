module WebGL.Game2d.Render exposing
    ( circle, image, ngon, rect, triangle
    , glyph
    , Opacity, Render, ScaleRotateSkew, Translate, Z, Height, Width
    , defaultEntitySettings
    )

{-|


# Renders

@docs circle, image, ngon, rect, triangle


# Other stuff

@docs glyph


# Types

@docs Opacity, Render, ScaleRotateSkew, Translate, Z, Height, Width


# Settings

@docs defaultEntitySettings

-}

import Math.Vector2 exposing (Vec2)
import Math.Vector3 exposing (Vec3)
import Math.Vector4 exposing (Vec4)
import WebGL exposing (Mesh, Shader)
import WebGL.Game2d.Internal exposing (setAlpha)
import WebGL.Game2d.Shader as Shader
import WebGL.Settings as WebGL exposing (Setting)
import WebGL.Settings.Blend as Blend
import WebGL.Settings.DepthTest as DepthTest
import WebGL.Texture exposing (Texture)


{-| Render is part of `Shape` that converts `Shape` into `Entity`

    rect : Vec3 -> Render
    rect color uP uT opacity =
        WebGL.entity
            Shader.vertNone
            Shader.fragFill
            Shader.mesh
            { color = color
            , opacity = opacity
            , uP = uP
            , uT = uT
            }

-}
type alias Render =
    Translate
    -> ScaleRotateSkew
    -> Z
    -> Opacity
    -> WebGL.Entity


{-| Css line `z-index` that is passed to the Render
-}
type alias Z =
    Float


{-| Vec2 representing part of transform matrix

    | 1 0 x |
    | 0 1 y |
    | 0 0 1 |

-}
type alias Translate =
    Vec2


{-| Vec4 representing part of transform matrix

    | x y 0 |
    | z w 0 |
    | 0 0 1 |

-}
type alias ScaleRotateSkew =
    Vec4


{-| Alias to Opacity property
-}
type alias Opacity =
    Float


{-| Alias to Width property
-}
type alias Width =
    Float


{-| Alias to Height property
-}
type alias Height =
    Float


{-| Rectangle render
-}
rect : Vec3 -> Render
rect color uP uT z opacity =
    WebGL.entityWith
        defaultEntitySettings
        Shader.vertNone
        Shader.fragFill
        Shader.mesh
        { color = setAlpha color opacity
        , uP = uP
        , uT = uT
        , z = z
        }


{-| Render circle or ellipse

Example [Playground.oval](Playground#oval):

-}
circle : Vec3 -> Render
circle color uP uT z opacity =
    WebGL.entityWith
        defaultEntitySettings
        Shader.vertRect
        Shader.fragCircle
        Shader.mesh
        { color = setAlpha color opacity
        , uP = uP
        , uT = uT
        , z = z
        }


{-| Render regular polygon
-}
ngon : Float -> Vec3 -> Render
ngon n color uP uT z opacity =
    WebGL.entityWith
        defaultEntitySettings
        Shader.vertRect
        Shader.fragNgon
        Shader.mesh
        { color = setAlpha color opacity
        , uP = uP
        , n = n
        , uT = uT
        , z = z
        }


{-| -}
image : Texture -> Vec2 -> Render
image uImg uImgSize uP uT z opacity =
    WebGL.entityWith
        defaultEntitySettings
        Shader.vertImage
        Shader.fragImage
        Shader.mesh
        { uP = uP
        , uT = uT
        , uImg = uImg
        , uImgSize = uImgSize
        , uA = opacity
        , z = z
        }


{-| Render tile from symmetrical tileset.

Same as [`tile`](#tile), but with color blending.

Used to draw text (font glyph)

-}
glyph : Texture -> Vec2 -> Vec2 -> Vec3 -> Float -> Vec2 -> Vec4 -> Float -> Float -> WebGL.Entity
glyph spriteSheet spriteSize imageSize color index translate scaleRotateSkew z opacity =
    WebGL.entityWith
        defaultEntitySettings
        Shader.vertTile
        Shader.fragImageColor
        Shader.mesh
        { uP = translate
        , uT = scaleRotateSkew
        , index = index
        , spriteSize = spriteSize
        , uImg = spriteSheet
        , uImgSize = imageSize
        , uA = opacity
        , color = setAlpha color opacity
        , z = z
        }


{-| Render triangle
-}
triangle : Vec3 -> ( Vec2, Vec2, Vec2 ) -> Render
triangle color ( vert0, vert1, vert2 ) translate scaleRotateSkew z opacity =
    WebGL.entityWith
        defaultEntitySettings
        Shader.vertTriangle
        Shader.fragFill
        Shader.meshTriangle
        { uP = translate
        , uT = scaleRotateSkew
        , vert0 = vert0
        , vert1 = vert1
        , vert2 = vert2
        , color = setAlpha color opacity
        , z = z
        }


{-| Make me optional and pass it to the each `Render` function
-}
defaultEntitySettings : List Setting
defaultEntitySettings =
    [ Blend.add Blend.srcAlpha Blend.oneMinusSrcAlpha
    , WebGL.colorMask True True True False
    , DepthTest.lessOrEqual { write = True, near = 0, far = 1 }
    ]
