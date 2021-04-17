module WebGL.Game2d.SolidShape exposing (shape, group, toEntities, SolidShape, Form(..))

{-|


# Texture-less converter

@docs shape, group, toEntities, SolidShape, Form

-}

import WebGL exposing (Entity)
import WebGL.Game2d.Internal exposing (applyOZ, createTrans)
import WebGL.Game2d.Internal.Transformation as Trans exposing (Transformation)
import WebGL.Game2d.Render exposing (Height, Render, Width)
import WebGL.Game2d.Shape as Shape exposing (GroupData, ShapeData)


{-| -}
shape : Width -> Height -> Render -> SolidShape
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
group : List SolidShape -> SolidShape
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
type Form
    = Form (ShapeData Render)
    | Group (GroupData (Shape.Shape Form))


{-| -}
type alias SolidShape =
    Shape.Shape Form


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
toEntities : Width -> Height -> List SolidShape -> List Entity
toEntities width height shapes =
    List.foldr (renderShape width height Trans.identity) [] shapes


renderShape : Width -> Height -> Transformation -> SolidShape -> List Entity -> List Entity
renderShape width height parent { x, y, z, a, sx, sy, o, data } acc =
    case data of
        Form shapeData ->
            let
                ( t1, t2 ) =
                    parent
                        |> createTrans (x * 2) (y * 2) (shapeData.width * sx) (shapeData.height * sy) a
                        |> Trans.scale (1 / width) (1 / height)
                        |> Trans.toGL
            in
            shapeData.render t2 t1 z o :: acc

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
