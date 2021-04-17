module WebGL.Game2d.Render exposing
    ( circle, image, ngon, rect, triangle
    , tile, glyph, sprite, tilemap
    , Opacity, Render, ScaleRotateSkew, Translate, Z, Height, Width
    , defaultEntitySettings
    )

{-|


# Basic Shapes

@docs circle, image, ngon, rect, triangle


# With Textures

@docs tile, glyph, sprite, tilemap


# Types

@docs Opacity, Render, ScaleRotateSkew, Translate, Z, Height, Width


# Settings

@docs defaultEntitySettings

-}

import Math.Vector2 exposing (Vec2, vec2)
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


{-| Show tile from a tileset.

All tiles are fixed size and placed into a grid, where the _first tile has a 0 index_
increasing left to right and top to bottom.

Example: having a 3x3 tileset with each tile of 16x24 pixels

    | 0 1 2 |
    | 3 4 5 |
    | 6 7 8 |

this draws the first tile of the second row

    tile 16 24 "sprites.png" 3

-}
tile : Texture -> Vec2 -> Vec2 -> Float -> Render
tile spriteSheet spriteSize imageSize index translate scaleRotateSkew z opacity =
    WebGL.entityWith
        defaultEntitySettings
        Shader.vertTile
        Shader.fragImage
        Shader.mesh
        { uP = translate
        , uT = scaleRotateSkew
        , index = index
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

For example, this lookup table is used to draw a T-shaped platform:

    | 2 2 2 |
    | 0 1 0 |
    | 0 1 0 |

which in turn uses this 3x3 tileset with each tile 16x24px.

    | 1 2 3 |
    | 4 5 6 |
    | 7 8 9 |

Finally, the function is used as follows:

    tilemap 16 24 "sprites.png" "lookuptable.png"

**Note:** tileset indexing starts from 1 when used in lookup table, since 0 is used to communicate "no tile here".


## Why

For tiny maps `tile` function is enough. However, when the game map grows in size performance issues creep in.
The underlying issue is that for each `tile` the WebGL rendering engine uses what is called an [Entity][1].
WebGL can handle a few thousands of such entities thus having a map with 100x100 tiles means to draw 10.000
entities for each frame - that’s way too much for WebGL.


## How it works

To avoid performance issues the idea is to draw a single WebGL `Entity` for each `tilemap` call by pushing
the composition of the map down the rendering pipeline.

To do that we need to pass to playground both the tileset and a 2D array of tile indices. The latter will
be used to look-up the correct tile.

You can visualize the lookup table like those mini-maps you see on video games HUD. Each lookup table pixel
represents a tile in the final tilemap, while the color _value_ of that pixel is an index telling which tile
to pick from the tileset.

All tiles are fixed size and placed into a grid, with indices increasing left to right and top to bottom. Notice
that a fully black but transparent pixel (`0x00000000`) means "no tile here" and nothing is rendered.
Hence, unlike `tile` function, this makes the lookup table indices to _start from 1_.

More details about this rendering technique can be found in [Brandon Jones’ blog][2].

[1]: https://package.elm-lang.org/packages/elm-community/webgl/latest/WebGL#Entity
[2]: https://blog.tojicode.com/2012/07/sprite-tile-maps-on-gpu.html

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


{-| Make me optional and pass it to the each `Render` function
-}
defaultEntitySettings : List Setting
defaultEntitySettings =
    [ Blend.add Blend.srcAlpha Blend.oneMinusSrcAlpha
    , WebGL.colorMask True True True False
    , DepthTest.lessOrEqual { write = True, near = 0, far = 1 }
    ]
