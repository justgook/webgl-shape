module NoTextures exposing (main)

import Browser
import Html exposing (Html)
import Math.Vector2 exposing (Vec2, vec2)
import Math.Vector3 exposing (Vec3)
import WebGL.Game2d as Game2d exposing (move, rgb)
import WebGL.Game2d.Render as Render exposing (Render)
import WebGL.Game2d.SolidShape as SolidShape exposing (Form(..), SolidShape, group)


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
            Game2d.toScreen 800 800
    in
    { entities =
        [ rectangle (rgb 239 41 41) 20 20 |> move 0 -50
        , circle (rgb 239 41 41) 20 |> move -50 0
        , hexagon (rgb 239 41 41) 50 |> move 50 0
        , triangle (rgb 41 239 41) ( vec2 -100 0, vec2 0 100, vec2 100 0 )
        , rectangle (rgb 41 41 239) 2 3000
        , rectangle (rgb 41 41 239) 3000 2
        ]
            |> SolidShape.toEntities screen
    , screen = screen
    }
        |> Game2d.view


rectangle : Vec3 -> Float -> Float -> SolidShape
rectangle color w h =
    Render.rect color |> SolidShape.shape w h


circle : Vec3 -> Float -> SolidShape
circle color r =
    Render.circle color
        |> SolidShape.shape (r * 2) (r * 2)


hexagon : Vec3 -> Float -> SolidShape
hexagon color r =
    Render.ngon 6 color
        |> SolidShape.shape (r * 2) (r * 2)


triangle : Vec3 -> ( Vec2, Vec2, Vec2 ) -> SolidShape
triangle color data =
    Render.triangle color data
        |> SolidShape.shape 1 1
