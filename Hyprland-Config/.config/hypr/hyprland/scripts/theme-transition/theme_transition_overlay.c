/*
 * theme_transition_overlay.c
 *
 * GTK4 + gtk4-layer-shell overlay: displays a screenshot with a
 * circle-reveal animation via GtkGLArea + GLSL.  The layer surface
 * sits on the OVERLAY layer — no window-rules needed at all.
 *
 * Build:  gcc -O2 -o theme_overlay theme_transition_overlay.c \
 *           $(pkg-config --cflags --libs gtk4 gtk4-layer-shell-0 epoxy) -lm
 * Usage:  ./theme_overlay <screenshot.png> <shader.frag> [duration]
 */

#define _POSIX_C_SOURCE 199309L

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <time.h>
#include <math.h>

#include <gtk/gtk.h>
#include <gtk4-layer-shell/gtk4-layer-shell.h>
#include <epoxy/gl.h>

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

/* ------------------------------------------------------------------ */
/* Config (set from argv)                                              */
/* ------------------------------------------------------------------ */
static const char *g_img_path;
static const char *g_frag_path;
static float       g_duration = 1.2f;

/* ------------------------------------------------------------------ */
/* GL state                                                            */
/* ------------------------------------------------------------------ */
static GLuint g_program;
static GLuint g_texture;
static GLuint g_vao, g_vbo;
static GLint  g_u_time, g_u_duration, g_u_resolution, g_u_texture;

/* ------------------------------------------------------------------ */
/* Animation                                                           */
/* ------------------------------------------------------------------ */
static struct timespec g_start;
static GtkWidget      *g_gl_area;

static double elapsed_sec(void) {
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    return (double)(now.tv_sec  - g_start.tv_sec)
         + (double)(now.tv_nsec - g_start.tv_nsec) / 1.0e9;
}

/* ------------------------------------------------------------------ */
/* Utility                                                             */
/* ------------------------------------------------------------------ */

static char *read_file_str(const char *path) {
    FILE *f = fopen(path, "rb");
    if (!f) { fprintf(stderr, "Cannot open: %s\n", path); exit(1); }
    fseek(f, 0, SEEK_END);
    long len = ftell(f);
    fseek(f, 0, SEEK_SET);
    char *buf = malloc((size_t)len + 1);
    if (!buf) { fclose(f); exit(1); }
    if ((long)fread(buf, 1, (size_t)len, f) != len) {
        fclose(f); free(buf);
        fprintf(stderr, "Read error: %s\n", path); exit(1);
    }
    buf[len] = '\0';
    fclose(f);
    return buf;
}

static GLuint compile_shader(GLenum type, const char *src) {
    GLuint s = glCreateShader(type);
    glShaderSource(s, 1, &src, NULL);
    glCompileShader(s);
    GLint ok;
    glGetShaderiv(s, GL_COMPILE_STATUS, &ok);
    if (!ok) {
        char log[2048];
        glGetShaderInfoLog(s, sizeof(log), NULL, log);
        fprintf(stderr, "Shader compile error:\n%s\n", log);
        exit(1);
    }
    return s;
}

/* ------------------------------------------------------------------ */
/* Vertex shader (embedded)                                            */
/* ------------------------------------------------------------------ */
static const char *vert_src =
    "#version 330 core\n"
    "layout(location=0) in vec2 aPos;\n"
    "layout(location=1) in vec2 aUV;\n"
    "out vec2 TexCoord;\n"
    "void main() {\n"
    "    TexCoord = aUV;\n"
    "    gl_Position = vec4(aPos, 0.0, 1.0);\n"
    "}\n";

/* ------------------------------------------------------------------ */
/* GtkGLArea callbacks                                                 */
/* ------------------------------------------------------------------ */

static void on_realize(GtkGLArea *area, gpointer data) {
    (void)data;
    gtk_gl_area_make_current(area);
    if (gtk_gl_area_get_error(area) != NULL) return;

    /* ---- shaders ---- */
    char *frag_src = read_file_str(g_frag_path);
    GLuint vs = compile_shader(GL_VERTEX_SHADER,   vert_src);
    GLuint fs = compile_shader(GL_FRAGMENT_SHADER, frag_src);
    free(frag_src);

    g_program = glCreateProgram();
    glAttachShader(g_program, vs);
    glAttachShader(g_program, fs);
    glLinkProgram(g_program);

    GLint ok;
    glGetProgramiv(g_program, GL_LINK_STATUS, &ok);
    if (!ok) {
        char log[2048];
        glGetProgramInfoLog(g_program, sizeof(log), NULL, log);
        fprintf(stderr, "Link error:\n%s\n", log);
        exit(1);
    }
    glDeleteShader(vs);
    glDeleteShader(fs);

    g_u_time       = glGetUniformLocation(g_program, "uTime");
    g_u_duration   = glGetUniformLocation(g_program, "uDuration");
    g_u_resolution = glGetUniformLocation(g_program, "uResolution");
    g_u_texture    = glGetUniformLocation(g_program, "screenTexture");

    /* ---- texture ---- */
    int w, h, c;
    stbi_set_flip_vertically_on_load(1);
    unsigned char *px = stbi_load(g_img_path, &w, &h, &c, 4);
    if (!px) { fprintf(stderr, "Failed to load: %s\n", g_img_path); exit(1); }

    glGenTextures(1, &g_texture);
    glBindTexture(GL_TEXTURE_2D, g_texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0,
                 GL_RGBA, GL_UNSIGNED_BYTE, px);
    stbi_image_free(px);

    /* ---- fullscreen quad ---- */
    static const float quad[] = {
        /* pos       uv      */
        -1.f, -1.f,  0.f, 0.f,
         1.f, -1.f,  1.f, 0.f,
         1.f,  1.f,  1.f, 1.f,
        -1.f, -1.f,  0.f, 0.f,
         1.f,  1.f,  1.f, 1.f,
        -1.f,  1.f,  0.f, 1.f,
    };

    glGenVertexArrays(1, &g_vao);
    glGenBuffers(1, &g_vbo);
    glBindVertexArray(g_vao);
    glBindBuffer(GL_ARRAY_BUFFER, g_vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(quad), quad, GL_STATIC_DRAW);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE,
                          4 * sizeof(float), (void *)0);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE,
                          4 * sizeof(float), (void *)(2 * sizeof(float)));
    glEnableVertexAttribArray(1);

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    /* start the clock */
    clock_gettime(CLOCK_MONOTONIC, &g_start);
}

static gboolean on_render(GtkGLArea *area, GdkGLContext *ctx, gpointer data) {
    (void)ctx; (void)data;
    int w = gtk_widget_get_width(GTK_WIDGET(area));
    int h = gtk_widget_get_height(GTK_WIDGET(area));
    float t = (float)elapsed_sec();

    glViewport(0, 0, w, h);
    glClearColor(0.f, 0.f, 0.f, 0.f);
    glClear(GL_COLOR_BUFFER_BIT);

    glUseProgram(g_program);
    glUniform1f(g_u_time,     t);
    glUniform1f(g_u_duration, g_duration);
    glUniform2f(g_u_resolution, (float)w, (float)h);
    glUniform1i(g_u_texture,  0);

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, g_texture);

    glBindVertexArray(g_vao);
    glDrawArrays(GL_TRIANGLES, 0, 6);

    return TRUE;   /* we handled rendering */
}

static void on_unrealize(GtkGLArea *area, gpointer data) {
    (void)data;
    gtk_gl_area_make_current(area);
    glDeleteTextures(1, &g_texture);
    glDeleteBuffers(1, &g_vbo);
    glDeleteVertexArrays(1, &g_vao);
    glDeleteProgram(g_program);
}

/* ------------------------------------------------------------------ */
/* Frame tick (drives animation, quits when done)                      */
/* ------------------------------------------------------------------ */

static gboolean on_tick(GtkWidget *widget, GdkFrameClock *clock, gpointer data) {
    (void)clock;
    if (elapsed_sec() > (double)g_duration + 0.05) {
        GApplication *app = G_APPLICATION(data);
        g_application_quit(app);
        return G_SOURCE_REMOVE;
    }
    gtk_widget_queue_draw(widget);
    return G_SOURCE_CONTINUE;
}

/* ------------------------------------------------------------------ */
/* App activate                                                        */
/* ------------------------------------------------------------------ */

static void activate(GtkApplication *app, gpointer data) {
    (void)data;
    GtkWindow *win = GTK_WINDOW(gtk_application_window_new(app));

    /* ---- Layer shell: OVERLAY layer, fullscreen, no input ---- */
    gtk_layer_init_for_window(win);
    gtk_layer_set_layer(win, GTK_LAYER_SHELL_LAYER_OVERLAY);
    gtk_layer_set_anchor(win, GTK_LAYER_SHELL_EDGE_TOP,    TRUE);
    gtk_layer_set_anchor(win, GTK_LAYER_SHELL_EDGE_BOTTOM, TRUE);
    gtk_layer_set_anchor(win, GTK_LAYER_SHELL_EDGE_LEFT,   TRUE);
    gtk_layer_set_anchor(win, GTK_LAYER_SHELL_EDGE_RIGHT,  TRUE);
    gtk_layer_set_exclusive_zone(win, -1);
    gtk_layer_set_keyboard_mode(win,
        GTK_LAYER_SHELL_KEYBOARD_MODE_NONE);
    gtk_layer_set_namespace(win, "theme-transition");

    /* ---- Transparent window background ---- */
    GtkCssProvider *css = gtk_css_provider_new();
    gtk_css_provider_load_from_string(css, "window { background: none; }");
    gtk_style_context_add_provider_for_display(
        gdk_display_get_default(),
        GTK_STYLE_PROVIDER(css),
        GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);

    /* ---- GL area ---- */
    g_gl_area = gtk_gl_area_new();
    g_signal_connect(g_gl_area, "realize",   G_CALLBACK(on_realize),   NULL);
    g_signal_connect(g_gl_area, "render",    G_CALLBACK(on_render),    NULL);
    g_signal_connect(g_gl_area, "unrealize", G_CALLBACK(on_unrealize), NULL);

    gtk_widget_add_tick_callback(g_gl_area, on_tick, app, NULL);

    gtk_window_set_child(win, g_gl_area);
    gtk_window_present(win);
}

/* ------------------------------------------------------------------ */
/* main                                                                */
/* ------------------------------------------------------------------ */

int main(int argc, char *argv[]) {
    if (argc < 3) {
        fprintf(stderr,
            "Usage: %s <screenshot.png> <shader.frag> [duration]\n", argv[0]);
        return 1;
    }

    g_img_path  = argv[1];
    g_frag_path = argv[2];
    if (argc >= 4) g_duration = (float)atof(argv[3]);

    /* Skip unnecessary GTK subsystems for faster startup */
    g_setenv("GTK_A11Y", "none", TRUE);

    GtkApplication *app = gtk_application_new(
        "com.hypr.themetransition", G_APPLICATION_NON_UNIQUE);
    g_signal_connect(app, "activate", G_CALLBACK(activate), NULL);

    /* Pass 0 args to GTK so our custom args aren't consumed */
    int status = g_application_run(G_APPLICATION(app), 0, NULL);
    g_object_unref(app);
    return status;
}
