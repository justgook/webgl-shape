module WebGL.Game2d.Util exposing
    ( size
    , tileFont, msdfFont
    )

{-|

@docs size


# Text printing

@docs tileFont, msdfFont

-}

import Math.Vector2 exposing (Vec2, vec2)
import Math.Vector3 exposing (Vec3)
import Math.Vector4
import WebGL.Game2d exposing (move)
import WebGL.Game2d.Render as Render
import WebGL.Game2d.TexturedShape as AutoTextures exposing (TexturedShape)
import WebGL.Texture exposing (Texture)


{-| Get texture size as Math.Vec2
-}
size : Texture -> Vec2
size t =
    WebGL.Texture.size t |> (\( w, h ) -> vec2 (toFloat w) (toFloat h))


{-| Create text from individual tiles
-}
tileFont : { charW : Float, charH : Float, src : key, getIndex : Char -> Int } -> Vec3 -> String -> TexturedShape key
tileFont { charW, charH, src, getIndex } color tt =
    src
        |> AutoTextures.textured
            (\t ->
                let
                    render index =
                        Render.glyph t (vec2 charW charH) (size t) color index
                            |> AutoTextures.shape charW charH
                in
                tt
                    |> String.toList
                    |> List.foldl
                        (\c ( acc, x ) ->
                            ( (getIndex c |> render |> move (toFloat x * charW) 0) :: acc
                            , x + 1
                            )
                        )
                        ( [], 0 )
                    |> Tuple.first
                    |> AutoTextures.group
                    |> move (charW * 0.5) 0
            )


{-| Multi-channel signed distance field atlas generator

<https://github.com/Chlumsky/msdf-atlas-gen>

-}
msdfFont : Float -> { src : key, getIndex : Char -> Maybe { c | uv : Math.Vector4.Vec4, w : Render.Width, h : Render.Height, x : Float, y : Float } } -> Vec3 -> String -> TexturedShape key
msdfFont aa { src, getIndex } color tt =
    let
        space =
            10
    in
    src
        |> AutoTextures.textured
            (\t ->
                let
                    render cc ( acc, x_ ) =
                        case getIndex cc of
                            Just { uv, w, h, x, y } ->
                                ( (Render.msdf aa t (size t) color uv
                                    |> AutoTextures.shape w h
                                    |> move (x_ + x) y
                                  )
                                    :: acc
                                , x_ + w
                                )

                            Nothing ->
                                ( acc, x_ + space )
                in
                tt
                    |> String.toList
                    |> List.foldl render ( [], 0 )
                    |> Tuple.first
                    |> AutoTextures.group
            )
