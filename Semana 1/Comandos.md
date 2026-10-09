# Guía de comandos Git y GitHub

> **Cómo leer esta guía:** el texto normal explica; los bloques grises (``` ```) son **comandos** listos para copiar y pegar (`Ctrl + ñ` o menú **Terminal → Nueva terminal**).

## Pasos 

1. Crear el archivo **README.md** con el título del proyecto.
2. Iniciar **Git** en la carpeta.
3. Preparar el archivo para guardarlo (**add**).
4. Guardar la primera versión (**commit**).
5. Nombrar la rama principal como **main**.
6. Conectar la carpeta con el repositorio de **GitHub**.
7. Subir el proyecto a GitHub (**push**).

---

## Comandos y su explicación

| Paso | Comando | ¿Qué hace? |
|:---:|---------|------------|
| 1 | `echo "# portafolio-so-cushicagua-salazar" >> README.md` | Crea el archivo `README.md` con el título de tu proyecto. Es la "portada" del repositorio en GitHub. |
| 2 | `git init` | Convierte tu carpeta en un repositorio Git para que pueda vigilar tus cambios. |
| 3 | `git add README.md` | Le dice a Git: "este archivo va a entrar en mi próxima versión". |
| 4 | `git commit -m "first commit"` | Guarda una "foto" de tu proyecto con un mensaje (aquí: primer guardado). |
| 5 | `git branch -M main` | Cambia el nombre de la rama principal a `main`, el estándar de GitHub. |
| 6 | `git remote add origin https://github.com/paulettepc/portafolio-so-cushicagua-salazar.git` | Une tu carpeta con tu repositorio en GitHub. `origin` es el apodo de esa dirección. |
| 7 | `git push -u origin main` | Envía tu proyecto a GitHub, a la rama `main`. El `-u` recuerda la conexión para la próxima vez. |

> ⚠️ En el paso 6, verifica que tu usuario y el nombre del repositorio coincidan con los de tu GitHub.

---

## 🔁 Para cambios futuros

| Comando | ¿Qué hace? |
|---------|------------|
| `git add .` | Prepara todos los archivos modificados. |
| `git commit -m "mensaje"` | Guarda los cambios con una descripción. |
| `git push` | Envía los cambios a GitHub. |

✨ Abre el archivo en VS Code y presiona `Ctrl + Shift + V` para ver la vista previa.