// Author: QRT Solutions. Production entrypoint; no administrative setup route.
import {handle} from './runtime.ts';
Deno.serve(handle);
