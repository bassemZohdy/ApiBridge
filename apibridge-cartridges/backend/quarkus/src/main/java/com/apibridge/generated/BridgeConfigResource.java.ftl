package com.apibridge.generated;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import java.util.LinkedHashMap;
import java.util.Map;

@Path("/api")
@ApplicationScoped
public class BridgeConfigResource {

    @ConfigProperty(name = "PAGINATION_PAGE_PARAM", defaultValue = "<#if (flags.pagination.pageParam)??>${flags.pagination.pageParam}<#else>page</#if>")
    String pageParam;

    @ConfigProperty(name = "PAGINATION_SIZE_PARAM", defaultValue = "<#if (flags.pagination.sizeParam)??>${flags.pagination.sizeParam}<#else>size</#if>")
    String sizeParam;

    @ConfigProperty(name = "PAGINATION_DEFAULT_PAGE_SIZE", defaultValue = "<#if (flags.pagination.defaultPageSize)??>${flags.pagination.defaultPageSize?c}<#else>20</#if>")
    int defaultPageSize;

    @ConfigProperty(name = "PAGINATION_SORT_PARAM", defaultValue = "<#if (flags.pagination.sortParam)??>${flags.pagination.sortParam}<#else>sort</#if>")
    String sortParam;

    @ConfigProperty(name = "PAGINATION_DIRECTION_PARAM", defaultValue = "<#if (flags.pagination.directionParam)??>${flags.pagination.directionParam}<#else>dir</#if>")
    String directionParam;

    @ConfigProperty(name = "CUSTOM_CSS_PATH", defaultValue = "")
    String customCssPath;

    @ConfigProperty(name = "SEARCH_PARAM", defaultValue = "q")
    String searchParam;

    @GET
    @Path("/bridge-config")
    @Produces(MediaType.APPLICATION_JSON)
    public Map<String, Object> config() {
        Map<String, Object> pagination = new LinkedHashMap<>();
        pagination.put("pageParam", pageParam);
        pagination.put("sizeParam", sizeParam);
        pagination.put("defaultPageSize", defaultPageSize);
        pagination.put("sortParam", sortParam);
        pagination.put("directionParam", directionParam);

        Map<String, Object> config = new LinkedHashMap<>();
        config.put("securityLevel", "${(flags.securityLevel)!""}");
        config.put("basePath", "${basePath}");
        config.put("enableTelemetry", ${((flags.enableTelemetry)!false)?c});
        config.put("apiVersion", "${(apiVersion)!""}");
        config.put("enableHealthCheck", ${((enableHealthCheck)!false)?c});
        config.put("enableSearch", ${((enableSearch)!false)?c});
        config.put("searchParam", searchParam);
        config.put("pagination", pagination);
        config.put("customCssPath", customCssPath);

        return config;
    }
}
