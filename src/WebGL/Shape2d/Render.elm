module WebGL.Shape2d.Render exposing
    ( circle, image, ngon, rect, triangle
    , tile, glyph, msdf, sprite, tilemap
    , Opacity, Render, ScaleRotateSkew, Translate, Z, Height, Width
    , defaultEntitySettings
    )

{-|


# Basic Shapes

@docs circle, image, ngon, rect, triangle


# With Textures

@docs tile, glyph, msdf, sprite, tilemap


# Types

@docs Opacity, Render, ScaleRotateSkew, Translate, Z, Height, Width


# Settings

@docs defaultEntitySettings

-}

import Math.Vector2 exposing (Vec2, vec2)
import Math.Vector3 exposing (Vec3)
import Math.Vector4 exposing (Vec4)
import WebGL exposing (Mesh, Shader)
import WebGL.Settings as WebGL exposing (Setting)
import WebGL.Settings.Blend as Blend
import WebGL.Settings.DepthTest as DepthTest
import WebGL.Shape2d.Internal exposing (setAlpha)
import WebGL.Shape2d.Shader as Shader
import WebGL.Texture exposing (Texture)


{-| Render is part of `Shape` that converts `Shape` into `Entity`

    rect : Vec3 -> Render
    rect color uP uT z opacity =
        WebGL.entityWith
            entitySettings
            Shader.vertNone
            Shader.fragFill
            Shader.mesh
            { color = setAlpha color opacity
            , uP = uP
            , uT = uT
            , z = z
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

    rectangle : Vec3 -> Float -> Float -> SolidShape
    rectangle color w h =
        Render.rect color
            |> SolidShape.shape w h

    shape =
        rectangle (rgb 255 0 0) 20 40

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


{-| Render triangle with free defined vertexes

    triangle : Vec3 -> ( Vec2, Vec2, Vec2 ) -> SolidShape
    triangle color data =
        Render.triangle color data
            |> SolidShape.shape 1 1

    shape =
        triangle (rgb 41 239 41)
            ( vec2 -100 0, vec2 0 100, vec2 100 0 )

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


{-| Render circle or ellipse

    circle : Vec3 -> Float -> SolidShape
    circle color r =
        Render.circle color
            |> SolidShape.shape (r * 2) (r * 2)

    shape =
        circle (rgb 255 0 0) 50

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

    hexagon : Vec3 -> Float -> SolidShape
    hexagon color r =
        Render.ngon 6 color
            |> SolidShape.shape (r * 2) (r * 2)

    shape =
        hexagon (rgb 255 0 0) 50

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


{-| Render an image

    image : Float -> Float -> key -> TexturedShape key
    image width height =
        AutoTextures.textured
            (\t ->
                t
                    |> Texture.size
                    |> (\( w, h ) -> Math.Vector2.vec2 (toFloat w) (toFloat h))
                    |> Render.image t
                    |> AutoTextures.shape width height
            )

    shape =
        image 200 200 "image.png"

-}
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


{-| Show tile from a tileset.

All tiles are fixed size and placed into a grid, where the _first tile has a 0 index_
increasing left to right and top to bottom.

Example: having a 3x3 tileset with each tile of 16x24 pixels

    | 0 1 2 |
    | 3 4 5 |
    | 6 7 8 |

this draws the first tile of the second row

    tile : Float -> Float -> key -> Int -> TexturedShape key
    tile tileW tileH tileset index =
        tileset
            |> AutoTextures.textured
                (\t ->
                    Render.tile t (vec2 tileW tileH) (Util.size t) index
                        |> AutoTextures.shape tileW tileH
                )

    shape =
        tile 16 24 "sprites.png" 3

-}
tile : Texture -> Vec2 -> Vec2 -> Int -> Render
tile spriteSheet spriteSize imageSize index translate scaleRotateSkew z opacity =
    WebGL.entityWith
        defaultEntitySettings
        Shader.vertTile
        Shader.fragImage
        Shader.mesh
        { uP = translate
        , uT = scaleRotateSkew
        , uI = index
        , spriteSize = spriteSize
        , uImg = spriteSheet
        , uImgSize = imageSize
        , uA = opacity
        , z = z
        }


{-| Show sprite from a sprite sheet.

Sprites can be placed anywhere in the sprite sheet and each can have different sizes.

Example: this draws a sprite of 16x24 pixels taking it from a sprite sheet,
starting at position `16,0` up to _including_ pixels at `31,23`

    sprite "sprites.png" { xmin = 16, xmax = 31, ymin = 0, ymax = 23 }

-}
sprite : Texture -> Vec2 -> Vec4 -> Render
sprite image_ imageSize uv translate scaleRotateSkew z opacity =
    WebGL.entityWith
        defaultEntitySettings
        Shader.vertSprite
        Shader.fragImage
        Shader.mesh
        { uP = translate
        , uT = scaleRotateSkew
        , uA = opacity
        , uImg = image_
        , uImgSize = imageSize
        , uUV = uv
        , z = z
        }


{-| Show tilemap from a tileset and a corresponding lookup table stored as a texture.

    tilemap : Float -> Float -> key -> key -> TexturedShape key
    tilemap tileW tileH tileset lut =
        AutoTextures.textured2
            (\t1 t2 ->
                let
                    ( w2, h2 ) =
                        Texture.size t2
                            |> Tuple.mapBoth (toFloat >> (*) tileW) (toFloat >> (*) tileH)
                in
                Render.tilemap tileW tileH t1 t2
                    |> AutoTextures.shape w2 h2
            )
            tileset
            lut

-}
tilemap : Float -> Float -> Texture -> Texture -> Render
tilemap tileW tileH tileset lut translate scaleRotateSkew z opacity =
    let
        ( w1, h1 ) =
            WebGL.Texture.size tileset
                |> Tuple.mapBoth toFloat toFloat

        ( w2, h2 ) =
            WebGL.Texture.size lut
                |> Tuple.mapBoth toFloat toFloat
    in
    WebGL.entityWith
        defaultEntitySettings
        Shader.vertImage
        Shader.fragTilemap
        Shader.mesh
        { uP = translate
        , uT = scaleRotateSkew
        , uA = opacity
        , uTileSize = vec2 tileW tileH
        , uAtlas = tileset
        , uAtlasSize = vec2 w1 h1
        , uLut = lut
        , uLutSize = vec2 w2 h2
        , z = z
        }


{-| Render tile from symmetrical tileset.

Same as [`tile`](#tile), but with color blending.

Used to draw text (font glyph)

-}
glyph : Texture -> Vec2 -> Vec2 -> Vec3 -> Int -> Render
glyph spriteSheet spriteSize imageSize color index translate scaleRotateSkew z opacity =
    WebGL.entityWith
        defaultEntitySettings
        Shader.vertTile
        Shader.fragGlyph
        Shader.mesh
        { uP = translate
        , uT = scaleRotateSkew
        , uI = index
        , spriteSize = spriteSize
        , uImg = spriteSheet
        , uImgSize = imageSize
        , uA = opacity
        , color = setAlpha color opacity
        , z = z
        }


{-| This is a utility for generating signed distance fields from vector shapes and font glyphs,
which serve as a texture representation that can be used in real-time graphics to efficiently reproduce said shapes.
Although it can also be used to generate conventional signed distance fields
best known from this Valve paper and pseudo-distance fields,
its primary purpose is to generate multi-channel distance fields, using a method I have developed.
Unlike monochrome distance fields,
they have the ability to reproduce sharp corners almost perfectly by utilizing all three color channels.
-}
msdf : Float -> Texture -> Vec2 -> Vec3 -> Vec4 -> Render
msdf aa t imgSize color uv translate scaleRotateSkew z opacity =
    WebGL.entityWith
        defaultEntitySettings
        Shader.vertSprite
        Shader.fragMSDF
        Shader.mesh
        { uP = translate
        , aa = aa
        , uT = scaleRotateSkew
        , uImg = t
        , uImgSize = imgSize
        , uUV = uv
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
