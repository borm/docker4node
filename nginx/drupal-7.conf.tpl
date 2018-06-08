upstream php {
    server {{ getenv "NGINX_BACKEND_HOST" }}:9000;
}

map $http_x_forwarded_proto $fastcgi_https {
    default $https;
    http '';
    https on;
}

server {
    server_name {{ getenv "NGINX_SERVER_NAME" "test" }};
    listen 80;

    root {{ getenv "NGINX_SERVER_ROOT" "/var/www/html/web/" }};
    index index.php;

    include fastcgi.conf;

    set $proxy 'http://node:3000';
    set $proxyReactApp 'http://node:3000/dist/app.js';
    if ($host = 'm.test.local') {
        set $proxyReactApp 'http://node:3000/dist/app.js';
    }

    location / {
        location ~* (sites/all/themes/custom/(desktop|mobile)/html/js/appCheckout\.(js))$ {
            proxy_pass $proxyReactApp;
            proxy_set_header Connection '';
            proxy_http_version 1.1;
            chunked_transfer_encoding off;
            proxy_buffering off;
            proxy_cache off;
        }
        location ~* (__webpack_hmr|\.hot-update\.(json|js))$ {
            proxy_pass $proxy;
            proxy_set_header Connection '';
            proxy_http_version 1.1;
            chunked_transfer_encoding off;
            proxy_buffering off;
            proxy_cache off;
        }

        location ~* ^.+\.(?:css|cur|js|jpe?g|gif|htc|ico|png|xml|otf|ttf|eot|woff|woff2|svg|svgz)$ {
            access_log {{ getenv "NGINX_STATIC_CONTENT_ACCESS_LOG" "off" }};
            expires {{ getenv "NGINX_STATIC_CONTENT_EXPIRES" "30d" }};
            tcp_nodelay off;
            open_file_cache {{ getenv "NGINX_STATIC_CONTENT_OPEN_FILE_CACHE" "max=3000 inactive=120s" }};
            open_file_cache_valid {{ getenv "NGINX_STATIC_CONTENT_OPEN_FILE_CACHE_VALID" "45s" }};
            open_file_cache_min_uses {{ getenv "NGINX_STATIC_CONTENT_OPEN_FILE_CACHE_MIN_USES" "2" }};
            open_file_cache_errors off;

            location ~* ^.+\.svgz$ {
                gzip off;
                add_header Content-Encoding gzip;
            }
        }

        location ~* ^.+\.(?:pdf|pptx?)$ {
            expires {{ getenv "NGINX_STATIC_CONTENT_EXPIRES" "30d" }};
            tcp_nodelay off;
        }

        location ~* ^(?:.+\.(?:htaccess|make|txt|engine|inc|info|install|module|profile|po|pot|sh|.*sql|test|theme|tpl(?:\.php)?|xtmpl)|code-style\.pl|/Entries.*|/Repository|/Root|/Tag|/Template)$ {
            return 404;
        }

        try_files $uri @drupal;
    }

    location @drupal {
        include fastcgi.conf;
        fastcgi_param QUERY_STRING $query_string;
        fastcgi_param SCRIPT_NAME /index.php;
        fastcgi_param SCRIPT_FILENAME $document_root/index.php;
        fastcgi_pass php;
        track_uploads {{ getenv "NGINX_DRUPAL_TRACK_UPLOADS" "uploads 60s" }};
    }

    location @drupal-no-args {
        include fastcgi.conf;
        fastcgi_param QUERY_STRING q=$uri;
        fastcgi_param SCRIPT_NAME /index.php;
        fastcgi_param SCRIPT_FILENAME $document_root/index.php;
        fastcgi_pass php;
    }

    location = /index.php {
        fastcgi_pass php;
    }

    location ^~ /.bzr {
        return 404;
    }

    location ^~ /.git {
        return 404;
    }

    location ^~ /.hg {
        return 404;
    }

    location ^~ /.svn {
        return 404;
    }

    location ^~ /.cvs {
        return 404;
    }

    location ^~ /patches {
        return 404;
    }

    location ^~ /backup {
        return 404;
    }

    location = /robots.txt {
        access_log {{ getenv "NGINX_STATIC_CONTENT_ACCESS_LOG" "off" }};
        try_files $uri @drupal-no-args;
    }

    location = /favicon.ico {
        expires {{ getenv "NGINX_STATIC_CONTENT_EXPIRES" "30d" }};
        try_files /favicon.ico @empty;
    }

    location ~* ^/.well-known/ {
        allow all;
    }

    location @empty {
        expires {{ getenv "NGINX_STATIC_CONTENT_EXPIRES" "30d" }};
        empty_gif;
    }

    location ~* ^.+\.php$ {
        return 404;
    }

    location ~ (?<upload_form_uri>.*)/x-progress-id:(?<upload_id>\d*) {
        rewrite ^ $upload_form_uri?X-Progress-ID=$upload_id;
    }

    location ~ ^/progress$ {
        upload_progress_json_output;
        report_uploads uploads;
    }

    include healthz.conf;
{{ if getenv "NGINX_SERVER_EXTRA_CONF_FILEPATH" }}
    include {{ getenv "NGINX_SERVER_EXTRA_CONF_FILEPATH" }};
{{ end }}
}
