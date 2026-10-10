const String hfClientId = '56370c68-410e-4af9-998b-baf53df6cc0c';
const String hfRedirectUri = 'com.hackathon.blind_vision_assistant://oauthredirect';
const String authEndpoint = 'https://huggingface.co/oauth/authorize';
const String tokenEndpoint = 'https://huggingface.co/oauth/token';
const String scope = 'openid profile read-repos';
const String modelName = 'gemma-3n-E2B-it-int4.task';
const String modelFullName = 'Gemma 3n E2B IT Int4';
const String downloadUrl =
    'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/$modelName?download=true';
const String modelCardUrl =
    'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview';
const String downloadStateKey = 'download_state';
const String downloadTaskIdKey = 'download_task_id';
const String authTokenKey = 'auth_token';
const String codeVerifierKey = 'code_verifier';
