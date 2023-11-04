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

#define PI 3.1415927
            float hash21(float2 p)
            {
                uint2 q = ((uint2)((int2)p))*uint2(1597334673u, 3812015801u);
                uint n = (q.x^q.y)*1597334673u;
                return float(n)/float(4294967295u);
            }

            float3 hash13(float p)
            {
                float3 p3 = frac(((float3)p)*float3(0.1031, 0.11369, 0.13787));
                p3 += dot(p3, p3.yzx+19.19);
                return frac(float3((p3.x+p3.y)*p3.z, (p3.x+p3.z)*p3.y, (p3.y+p3.z)*p3.x));
            }

            float rainDrops(float2 st, float time, float size)
            {
                float2 uv = st*size;
                uv.x *= iResolution.x/iResolution.y;
                float2 gridUv = frac(uv)-0.5;
                float2 id = floor(uv);
                float3 h = (hash13(id.x*467.983+id.y*1294.387)-0.5)*0.8;
                float2 dropUv = gridUv-h.xy;
                float4 noise = textureLod(_SecondTex, id*0.05, 0.);
                float drop = smoothstep(0.25, 0., length(dropUv))*max(0., 1.-frac(time*(noise.b+0.1)*0.2+noise.g)*2.);
                return drop;
            }

            float2 wigglyDrops(float2 st, float time, float size)
            {
                float2 wigglyDropAspect = float2(2., 1.);
                float2 uv = st*size*wigglyDropAspect;
                uv.x *= iResolution.x/iResolution.y;
                uv.y += time*0.23;
                float2 gridUv = frac(uv)-0.5;
                float2 id = floor(uv);
                float h = hash21(id);
                time += h*2.*PI;
                float w = st.y*10.;
                float dx = (h-0.5)*0.8;
                dx += (0.3-abs(dx))*pow(sin(w), 2.)*sin(2.*w)*pow(cos(w), 3.)*1.05;
                float dy = -sin(time+sin(time+sin(time)*0.5))*0.45;
                dy -= (gridUv.x-dx)*(gridUv.x-dx);
                float2 dropUv = (gridUv-float2(dx, dy))/wigglyDropAspect;
                float drop = smoothstep(0.06, 0., length(dropUv));
                float2 trailUv = (gridUv-float2(dx, time*0.23))/wigglyDropAspect;
                trailUv.y = (frac(trailUv.y*8.)-0.5)/8.;
                float trailDrop = smoothstep(0.03, 0., length(trailUv));
                trailDrop *= smoothstep(-0.05, 0.05, dropUv.y)*smoothstep(0.4, dy, gridUv.y)*(1.-step(0.4, gridUv.y));
                float fogTrail = smoothstep(-0.05, 0.05, dropUv.y)*smoothstep(0.4, dy, gridUv.y)*smoothstep(0.05, 0.01, abs(dropUv.x))*(1.-step(0.4, gridUv.y));
                return float2(drop+trailDrop, fogTrail);
            }

            float2 getDrops(float2 st, float time)
            {
                float2 largeDrops = wigglyDrops(st, time*2., 1.6);
                float2 mediumDrops = wigglyDrops(st+2.65, (time+1296.675)*1.4, 2.5);
                float2 smallDrops = wigglyDrops(st-1.67, time-896.431, 3.6);
                float rain = rainDrops(st, time, 20.);
                float2 drops;
                drops.y = max(largeDrops.y, max(mediumDrops.y, smallDrops.y));
                drops.x = smoothstep(0.4, 2., (1.-drops.y)*rain+largeDrops.x+mediumDrops.x+smallDrops.x);
                return drops;
            }

            float4 frag (v2f __vertex_output) : SV_Target
            {
                vertex_output = __vertex_output;
                float4 fragColor = 0;
                float2 fragCoord = vertex_output.uv * _Resolution;
                float2 st = fragCoord/iResolution.xy;
                float time = glsl_mod(_Time.y+100., 7200.);
                float2 drops = getDrops(st, time);
                float2 offset = drops.xy;
                float lod = (1.-drops.y)*4.8;
                float2 dropsX = getDrops(st+float2(0.001, 0.), time);
                float2 dropsY = getDrops(st+float2(0., 0.001), time);
                float3 normal = float3(dropsX.x-drops.x, dropsY.x-drops.x, 0.);
                normal.z = sqrt(1.-normal.x*normal.x-normal.y*normal.y);
                normal = normalize(normal);
                float lightning = sin(time*sin(time*30.));
                float lightningTime = glsl_mod(time, 10.)/9.9;
                lightning *= 1.-smoothstep(0., 0.1, lightningTime)+smoothstep(0.9, 1., lightningTime);
                float3 col = textureLod(_MainTex, st+normal.xy*3., lod).rgb;
                col *= 1.+lightning;
                col *= float3(1., 0.8, 0.7);
                col += drops.y>0. ? float3(0.5, -0.1, -0.15)*drops.y : ((float3)0.);
                col *= drops.x>0. ? float3(0.8, 0.2, 0.1)*(1.-drops.x) : ((float3)1.);
                col = lerp(col, col*smoothstep(0.8, 0.35, length(st-0.5)), 0.6);
                fragColor = float4(col, 1.);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}
