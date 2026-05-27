package com.apibridge.generated;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class BridgeConfigController {

    @Value("${r"${PAGINATION_PAGE_PARAM:"}<#if (flags.pagination.pageParam)??>${flags.pagination.pageParam}<#else>page</#if>${r"}"}")
    private String pageParam;

    @Value("${r"${PAGINATION_SIZE_PARAM:"}<#if (flags.pagination.sizeParam)??>${flags.pagination.sizeParam}<#else>size</#if>${r"}"}")
    private String sizeParam;

    @Value("${r"${PAGINATION_DEFAULT_PAGE_SIZE:"}<#if (flags.pagination.defaultPageSize)??>${flags.pagination.defaultPageSize?c}<#else>20</#if>${r"}"}")
    private int defaultPageSize;

    @Value("${r"${PAGINATION_SORT_PARAM:"}<#if (flags.pagination.sortParam)??>${flags.pagination.sortParam}<#else>sort</#if>${r"}"}")
    private String sortParam;

    @Value("${r"${PAGINATION_DIRECTION_PARAM:"}<#if (flags.pagination.directionParam)??>${flags.pagination.directionParam}<#else>dir</#if>${r"}"}")
    private String directionParam;

    @GetMapping("/bridge-config")
    public ResponseEntity<Map<String, Object>> config() {
        Map<String, Object> pagination = new LinkedHashMap<>();
        pagination.put("pageParam", pageParam);
        pagination.put("sizeParam", sizeParam);
        pagination.put("defaultPageSize", defaultPageSize);
        pagination.put("sortParam", sortParam);
        pagination.put("directionParam", directionParam);

        Map<String, Object> config = new LinkedHashMap<>();
        config.put("navigationMode", "${(flags.navigationMode)!"spa"}");
        config.put("pagination", pagination);

        return ResponseEntity.ok(config);
    }
}
