package com.apibridge.generated;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
<#if (flags.enableAuditLog)!false>
import org.springframework.scheduling.annotation.EnableAsync;
</#if>

<#if (flags.enableAuditLog)!false>
@EnableAsync
</#if>
@SpringBootApplication
public class Application {

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
