#version 300 es
precision highp float;

const vec2 verts[4] = vec2[4] (
    vec2(-0.8f, -0.8f ),
    vec2( 0.8f, -0.8f ),
    vec2(-0.8f,  0.8f ),
    vec2( 0.8f,  0.8f )
);

void main() {
	gl_Position = vec4( verts[gl_VertexID], 0, 1 );
}
