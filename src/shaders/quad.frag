#version 300 es

precision highp float;
uniform vec4 color;

out vec4 shader_color;

void main() {
	shader_color = color;
}
