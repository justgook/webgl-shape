module WebGL.Game2d.TexturedShape exposing
    ( shape, group, toEntities, TexturedShape, Form(..)
    , Textures, Missing
    )

{-|


# Shapes with textures

Same as `ShapeSolid` but also can render shapes that needs textures

@docs shape, group, toEntities, TexturedShape, Form


# Textures

@docs Textures, Missing

-}

import WebGL exposing (Entity)
import WebGL.Game2d.Internal exposing (applyOZ, createTrans)
import WebGL.Game2d.Render exposing (Height, Render, Width)
import WebGL.Game2d.Shape as Shape exposing (GroupData, ShapeData, TexturedData)
import WebGL.Game2d.Transformation as Trans exposing (Transformation)
import WebGL.Texture exposing (Texture)


{-| -}
type alias Textures a =
    a -> Maybe Texture


{-| -}
type alias Missing texture acc =
    texture -> acc -> acc


{-| -}
shape : Width -> Height -> Render -> TexturedShape texture
shape w h render =
    { width = w, height = h, render = render }
        |> Form
        |> Shape.create


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
toEntities : Width -> Height -> Textures key -> Missing key acc -> acc -> List (TexturedShape key) -> ( List Entity, acc )
toEntities width height textures insertMissing missing shapes =
    List.foldr (renderShape width height textures insertMissing Trans.identity) ( [], missing ) shapes


renderShape : Width -> Height -> Textures key -> Missing key acc -> Transformation -> TexturedShape key -> ( List Entity, acc ) -> ( List Entity, acc )
renderShape width height textures insertMissing parent { x, y, z, a, sx, sy, o, data } (( entities, missing ) as acc) =
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
            case textures src of
                Just texture ->
                    renderShape
                        width
                        height
                        textures
                        insertMissing
                        (createTrans (x * 2) (y * 2) sx sy a parent)
                        (fn texture |> applyOZ o z)
                        acc

                Nothing ->
                    ( entities, insertMissing src missing )

        Group shapes ->
            let
                fn =
                    applyOZ o z
                        >> renderShape
                            width
                            height
                            textures
                            insertMissing
                            (createTrans (x * 2) (y * 2) sx sy a parent)
            in
            List.foldr fn acc shapes
