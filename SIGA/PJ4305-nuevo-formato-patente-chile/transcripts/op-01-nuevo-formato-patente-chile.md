# OP-01: Permitir nuevo formato de patentes (Placa) para Chile

## Problema
El módulo de emisión valida el campo patente solo con el formato LLLL-NN.
El nuevo formato del Ministerio de Transportes (LLLLL-N) entra en vigor en 2H 2026.
Se necesita implementar esta nueva validación; es más urgente ya que esta nueva
matriculación entra en vigor a partir de agosto.

## Solución
Actualizar la validación del campo patente para aceptar exactamente dos formatos:
(1) 4 letras + 2 números (LLLL-NN); (2) 5 letras + 1 número (LLLLL-N).
Cualquier otro formato debe ser rechazado.
