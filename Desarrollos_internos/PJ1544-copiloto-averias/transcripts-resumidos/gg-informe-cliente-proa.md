# Condensado — gg-informe-cliente-proa

Réplica del informe por cliente para un segundo cliente. Su aportación es la **lección de
mantenibilidad**, no una funcionalidad nueva.

## Decisiones
- Se decidió duplicar el proceso completo por cliente en vez de parametrizarlo. Consecuencia
  documentada: mismo código en dos sitios, con los mismos defectos y arreglos que hay que
  propagar a mano.

## Alcance / requerimientos
- Funcionalmente idéntico al informe por cliente: lo único que cambia entre clientes es la
  lista de razones sociales y el título del informe.
- Requisito de diseño para nuestra versión: **el informe por cliente debe ser un parámetro, no
  una copia** (un selector de cliente/distribuidor sobre la misma vista).

## Riesgos / pendientes
- La caché de resultados queda ligada al cliente con el que se generó: mezclar clientes en la
  misma carpeta corrompe los datos.
