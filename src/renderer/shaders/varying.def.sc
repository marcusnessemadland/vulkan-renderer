vec3 a_position  : POSITION;
vec3 a_normal    : NORMAL;
vec3 a_tangent   : TANGENT;
vec2 a_texcoord0 : TEXCOORD0;

vec3 v_worldpos  : POSITION1 = vec3(0.0, 0.0, 0.0);
vec3 v_normal    : NORMAL    = vec3(0.0, 0.0, 0.0);
vec3 v_tangent   : TANGENT   = vec3(0.0, 0.0, 0.0);
vec2 v_texcoord0 : TEXCOORD0 = vec2(0.0, 0.0);
vec3 v_dir       : TEXCOORD1 = vec3(0.0, 0.0, 0.0);
vec4 i_data0     : TEXCOORD2 = vec4(0.0, 0.0, 0.0, 0.0); 
vec4 i_data1     : TEXCOORD3 = vec4(0.0, 0.0, 0.0, 0.0);
vec4 i_data2     : TEXCOORD4 = vec4(0.0, 0.0, 0.0, 0.0);
vec4 i_data3     : TEXCOORD5 = vec4(0.0, 0.0, 0.0, 0.0);
