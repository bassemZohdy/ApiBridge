package com.apibridge.generated;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import java.util.LinkedHashMap;
import java.util.Map;

@Path("/api")
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
        config.put("navigationMode", "${(flags.navigationMode)!"spa"}");
        config.put("pagination", pagination);

        return config;
    }
}
