Shader "Converted/Template"
{
    Properties
    {
        _MainTex ("iChannel0", 2D) = "white" {}
        _SecondTex ("iChannel1", 2D) = "white" {}
        _ThirdTex ("iChannel2", 2D) = "white" {}
        _FourthTex ("iChannel3", 2D) = "white" {}
        _Mouse ("Mouse", Vector) = (0.5, 0.5, 0.5, 0.5)
        [ToggleUI] _GammaCorrect ("Gamma Correction", Float) = 1
        _Resolution ("Resolution (Change if AA is bad)", Range(1, 1024)) = 1
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            // Built-in properties
            sampler2D _MainTex;   float4 _MainTex_TexelSize;
            sampler2D _SecondTex; float4 _SecondTex_TexelSize;
            sampler2D _ThirdTex;  float4 _ThirdTex_TexelSize;
            sampler2D _FourthTex; float4 _FourthTex_TexelSize;
            float4 _Mouse;
            float _GammaCorrect;
            float _Resolution;

            // GLSL Compatability macros
            #define glsl_mod(x,y) (((x)-(y)*floor((x)/(y))))
            #define texelFetch(ch, uv, lod) tex2Dlod(ch, float4((uv).xy * ch##_TexelSize.xy + ch##_TexelSize.xy * 0.5, 0, lod))
            #define textureLod(ch, uv, lod) tex2Dlod(ch, float4(uv, 0, lod))
            #define iResolution float3(_Resolution, _Resolution, _Resolution)
            #define iFrame (floor(_Time.y / 60))
            #define iChannelTime float4(_Time.y, _Time.y, _Time.y, _Time.y)
            #define iDate float4(2020, 6, 18, 30)
            #define iSampleRate (44100)
            #define iChannelResolution float4x4(                      \
                _MainTex_TexelSize.z,   _MainTex_TexelSize.w,   0, 0, \
                _SecondTex_TexelSize.z, _SecondTex_TexelSize.w, 0, 0, \
                _ThirdTex_TexelSize.z,  _ThirdTex_TexelSize.w,  0, 0, \
                _FourthTex_TexelSize.z, _FourthTex_TexelSize.w, 0, 0)

            // Global access to uv data
            static v2f vertex_output;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv =  v.uv;
                return o;
            }

#define S(a, b, t) smoothstep(a, b, t)
#define size 0.2
#define CAM // uncomment to switch from webcam input to iChannel1 texture
            float3 N13(float p)
            {
                float3 p3 = frac(((float3)p)*float3(0.1031, 0.11369, 0.13787));
                p3 += dot(p3, p3.yzx+19.19);
                return frac(float3((p3.x+p3.y)*p3.z, (p3.x+p3.z)*p3.y, (p3.y+p3.z)*p3.x));
            }

            float4 N14(float t)
            {
                return frac(sin(t*float4(123., 1024., 1456., 264.))*float4(6547., 345., 8799., 1564.));
            }

            float N(float t)
            {
                return frac(sin(t*12345.564)*7658.76);
            }

            float Saw(float b, float t)
            {
                return S(0., b, t)*S(1., b, t);
            }

            float2 Drops(float2 uv, float t)
            {
                float2 UV = uv;
                uv.y += t*0.8;
                float2 a = float2(6., 1.);
                float2 grid = a*2.;
                float2 id = floor(uv*grid);
                float colShift = N(id.x);
                uv.y += colShift;
                id = floor(uv*grid);
                float3 n = N13(id.x*35.2+id.y*2376.1);
                float2 st = frac(uv*grid)-float2(0.5, 0);
                float x = n.x-0.5;
                float y = UV.y*20.;
                float distort = sin(y+sin(y));
                x += distort*(0.5-abs(x))*(n.z-0.5);
                x *= 0.7;
                float ti = frac(t+n.z);
                y = (Saw(0.85, ti)-0.5)*0.9+0.5;
                float2 p = float2(x, y);
                float d = length((st-p)*a.yx);
                float dSize = size;
                float Drop = S(dSize, 0., d);
                float r = sqrt(S(1., y, st.y));
                float cd = abs(st.x-x);
                float trail = S((dSize*0.5+0.03)*r, (dSize*0.5-0.05)*r, cd);
                float trailFront = S(-0.02, 0.02, st.y-y);
                trail *= trailFront;
                y = UV.y;
                y += N(id.x);
                float trail2 = S(dSize*r, 0., cd);
                float droplets = max(0., sin(y*(1.-y)*120.)-st.y)*trail2*trailFront*n.z;
                y = frac(y*10.)+(st.y-0.5);
                float dd = length(st-float2(x, y));
                droplets = S(dSize*N(id.x), 0., dd);
                float m = Drop+droplets*r*trailFront;
#ifdef DEBUG
                m += st.x>a.y*0.45||st.y>a.x*0.165 ? 1.2 : 0.;
#endif
                return float2(m, trail);
            }

            float StaticDrops(float2 uv, float t)
            {
                uv *= 30.;
                float2 id = floor(uv);
                uv = frac(uv)-0.5;
                float3 n = N13(id.x*107.45+id.y*3543.654);
                float2 p = (n.xy-0.5)*0.5;
                float d = length(uv-p);
                float fade = Saw(0.025, frac(t+n.z));
                float c = S(size, 0., d)*frac(n.z*10.)*fade;
                return c;
            }

            float2 Rain(float2 uv, float t)
            {
                float s = StaticDrops(uv, t);
                float2 r1 = Drops(uv, t);
                float2 r2 = Drops(uv*1.8, t);
#ifdef DEBUG
                float c = r1.x;
#else
                float c = s+r1.x+r2.x;
#endif
                c = S(0.3, 1., c);
#ifdef DEBUG
                return float2(c, r1.y);
#else
                return float2(c, max(r1.y, r2.y));
#endif
            }

            float4 frag (v2f __vertex_output) : SV_Target
            {
                vertex_output = __vertex_output;
                float4 fragColor = 0;
                float2 fragCoord = vertex_output.uv * _Resolution;
                float2 uv = (fragCoord.xy-0.5*iResolution.xy)/iResolution.y;
                float2 UV = fragCoord.xy/iResolution.xy;
                float T = _Time.y;
                float t = T*0.2;
                float rainAmount = 0.8;
                UV = (UV-0.5)*0.9+0.5;
                float2 c = Rain(uv, t);
                float2 e = float2(0.001, 0.);
                float cx = Rain(uv+e, t).x;
                float cy = Rain(uv+e.yx, t).x;
                float2 n = float2(cx-c.x, cy-c.x);
#ifdef CAM
                float Pi = 6.2831855;
                float Directions = 32.;
                float Quality = 8.;
                float Size = 32.;
                float2 Radius = Size/iResolution.xy;
                float3 col = tex2D(_MainTex, UV).rgb;
                for (float d = 0.;d<Pi; d += Pi/Directions)
                {
                    for (float i = 1./Quality;i<=1.; i += 1./Quality)
                    {
#ifdef DEBUG
                        float3 tex = tex2D(_MainTex, UV+c+float2(cos(d), sin(d))*Radius*i).rgb;
#else
                        float3 tex = tex2D(_MainTex, UV+n+float2(cos(d), sin(d))*Radius*i).rgb;
#endif
                        col += tex;
                    }
                }
                col /= Quality*Directions-0.;
                float3 tex = tex2D(_MainTex, UV+n).rgb;
                c.y = clamp(c.y, 0., 1.);
                col -= c.y;
                col += c.y*(tex+0.6);
#else
                float3 col = textureLod(_SecondTex, UV+n, focus).rgb;
#endif
                fragColor = float4(col, 1.);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}
