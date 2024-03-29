module WebGL.Shape2d.SolidShape exposing
    ( toEntities
    , shape, group, SolidShape, Form(..)
    )

{-|


# Texture-less converter

@docs toEntities
@docs shape, group, SolidShape, Form

-}

import WebGL exposing (Entity)
import WebGL.Shape2d.Internal exposing (applyOZ, createTrans)
import WebGL.Shape2d.Internal.Transformation as Trans exposing (Transformation)
import WebGL.Shape2d.Render exposing (Height, Render, Width)
import WebGL.Shape2d.Shape as Shape exposing (GroupData, ShapeData)


{-| Create [`SolidShape`](#SolidShape) from [`Render`](WebGL-Game2d-Render#Render)

    rectangle : Color -> Width -> Height -> SolidShape
    rectangle color w h =
        Render.rect color |> SolidShape.shape w h

-}
shape : Width -> Height -> Render -> SolidShape
shape w h render =
    { width = w, height = h, render = render }
        |> Form
        |> Shape.create


{-| Put shapes together so you can [`move`](WebGL-Game2d#move) and [`rotate`](WebGL-Game2d#rotate)
them as a group. Maybe you want to put a bunch of stars in the sky:

    shapes =
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


{-| Converts [`List SolidShape`](#SolidShape) to WebGL entities

    main : Program () () a
    main =
        Browser.sandbox
            { init = ()
            , view = view
            , update = \_ model -> model
            }

    view : model -> Html msg
    view _ =
        let
            screen =
                Game2d.toScreen 100 100
        in
        { entities =
            [ rectangle (rgb 239 41 41) 20 20 ]
                |> SolidShape.toEntities screen
        , screen = screen
        }
            |> Game2d.view

-}
toEntities : { a | width : Width, height : Height } -> List SolidShape -> List Entity
toEntities { width, height } shapes =
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
