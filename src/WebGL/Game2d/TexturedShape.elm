module WebGL.Game2d.TexturedShape exposing
    ( toEntities, shape, group, textured, textured2, textured3, textured4, textured5, TexturedShape, Form(..)
    , TextureLoader(..)
    )

{-|


# Shapes with textures

Same as `ShapeSolid` but also can render shapes that needs textures

@docs toEntities, shape, group, textured, textured2, textured3, textured4, textured5, TexturedShape, Form


# Textures

@docs TextureLoader

-}

import WebGL exposing (Entity)
import WebGL.Game2d.Internal exposing (applyOZ, createTrans)
import WebGL.Game2d.Internal.Transformation as Trans exposing (Transformation)
import WebGL.Game2d.Render exposing (Height, Render, Width)
import WebGL.Game2d.Shape as Shape exposing (GroupData, ShapeData, TexturedData)
import WebGL.Texture as Texture exposing (Texture)


{-| -}
type TextureLoader key
    = TextureLoader
        { get : key -> Maybe Texture
        , missing : key -> TextureLoader key
        , extract : () -> ( TextureLoader key, List key )
        , insert : key -> Texture -> TextureLoader key
        }


{-| -}
shape : Width -> Height -> Render -> TexturedShape texture
shape w h render =
    { width = w, height = h, render = render }
        |> Form
        |> Shape.create


{-| -}
textured : (Texture -> TexturedShape texture) -> texture -> TexturedShape texture
textured render src =
    { src = src, fn = render }
        |> Textured
        |> Shape.create


{-| -}
textured2 : (Texture -> Texture -> TexturedShape key) -> key -> key -> TexturedShape key
textured2 render src1 src2 =
    textured (\a -> textured (render a) src2) src1


{-| -}
textured3 : (Texture -> Texture -> Texture -> TexturedShape key) -> key -> key -> key -> TexturedShape key
textured3 render src1 src2 src3 =
    textured (\a -> textured (\b -> textured (render a b) src3) src2) src1


{-| -}
textured4 : (Texture -> Texture -> Texture -> Texture -> TexturedShape key) -> key -> key -> key -> key -> TexturedShape key
textured4 render src1 src2 src3 src4 =
    textured (\a -> textured (\b -> textured (\c -> textured (render a b c) src4) src3) src2) src1


{-| -}
textured5 : (Texture -> Texture -> Texture -> Texture -> Texture -> TexturedShape key) -> key -> key -> key -> key -> key -> TexturedShape key
textured5 render src1 src2 src3 src4 src5 =
    textured
        (\a ->
            textured
                (\b ->
                    textured
                        (\c -> textured (\d -> textured (render a b c d) src5) src4)
                        src3
                )
                src2
        )
        src1


{-| Put shapes together so you can [`move`](#move) and [`rotate`](#rotate)
them as a group. Maybe you want to put a bunch of stars in the sky:

    import Playground exposing (..)

    main =
        picture
            [ star
                |> move 100 100
                |> rotate 5
            , star
                |> move -120 40
                |> rotate 20
            , star
                |> move 80 -150
                |> rotate 32
            , star
                |> move -90 -30
                |> rotate -16
            ]

    star =
        group
            [ triangle yellow 20
            , triangle yellow 20
                |> rotate 180
            ]

-}
group : List (TexturedShape key) -> TexturedShape key
group shapes =
    { x = 0
    , y = 0
    , z = 0
    , a = 0
    , sx = 1
    , sy = 1
    , o = 1
    , data = Group shapes
    }


{-| -}
type Form key
    = Form (ShapeData Render)
    | Group (GroupData (Shape.Shape (Form key)))
    | Textured (TexturedData key (TexturedShape key))


{-| -}
type alias TexturedShape key =
    Shape.Shape (Form key)


{-| Converts [`List Shape`](#Shape) to WebGL entities

    import WebGL
    import WebGL.Game2d.SolidShape exposing (toEntities)

    rectangle =
        ...

    screen =
        { width = 100, height = 100 }

    main =
        toEntities [ rectangle red 30 30 ]
            |> Webgl.toHtml [ width 100, height 100 ]

-}
toEntities : Width -> Height -> TextureLoader key -> List (TexturedShape key) -> ( List Entity, TextureLoader key )
toEntities width height textures shapes =
    List.foldr (renderShape width height Trans.identity) ( [], textures ) shapes


renderShape : Width -> Height -> Transformation -> TexturedShape key -> ( List Entity, TextureLoader key ) -> ( List Entity, TextureLoader key )
renderShape width height parent { x, y, z, a, sx, sy, o, data } (( entities, (TextureLoader loader) as missing ) as acc) =
    case data of
        Form shapeData ->
            let
                ( t1, t2 ) =
                    parent
                        |> createTrans (x * 2) (y * 2) (shapeData.width * sx) (shapeData.height * sy) a
                        |> Trans.scale (1 / width) (1 / height)
                        |> Trans.toGL
            in
            ( shapeData.render t2 t1 z o :: entities, missing )

        Textured { src, fn } ->
            case loader.get src of
                Just texture ->
                    renderShape
                        width
                        height
                        (createTrans (x * 2) (y * 2) sx sy a parent)
                        (fn texture |> applyOZ o z)
                        acc

                Nothing ->
                    ( entities, loader.missing src )

        Group shapes ->
            let
                fn =
                    applyOZ o z
                        >> renderShape
                            width
                            height
                            (createTrans (x * 2) (y * 2) sx sy a parent)
            in
            List.foldr fn acc shapes
