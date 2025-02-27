locals {
  declared_app_components = [
    for app_component in var.app_components :
    {
      name = app_component["app_component_name"]
      type = app_component["app_component_type"]
      resourceNames = [
        for resource in app_component["resources"] :
        resource["resource_name"]
      ]
    }
  ]

  app_common_app_component = [
    {
      name = "appcommon"
      type = "AWS::ResilienceHub::AppCommonAppComponent",
      resourceNames : []
    }
  ]

  app_components = tolist(concat(local.declared_app_components, local.app_common_app_component))

  resources_list = flatten([
    for component in var.app_components : [
      for resource in component["resources"] : {
        resource_name            = resource["resource_name"]
        resource_type            = resource["resource_type"]
        resource_identifier_type = resource["resource_identifier_type"]
        resource_identifier      = resource["resource_identifier"]
        resource_region          = resource["resource_region"]
      }
    ]
  ])

  state_file_mapping = [
    {
      mapping_type = "Terraform"
      physical_resource_id = {
        identifier = var.s3_state_file_url
        type       = "Native"
      }
      terraform_source_name = "TerraformStateFile"
    }
  ]

  resources_mappings_only = [
    for resource in local.resources_list :
    {
      mapping_type = "Resource"
      physical_resource_id = {
        identifier = resource["resource_identifier"]
        type       = resource["resource_identifier_type"]
        aws_region = resource["resource_region"]
      }
      resource_name = resource["resource_name"]
    }
  ]

  resource_mappings = concat(local.resources_mappings_only, local.state_file_mapping)

  resources_json = [
    for resource in local.resources_list :
    {
      logicalResourceId = {
        identifier = resource["resource_name"]
      }
      type = resource["resource_type"]
      name = resource["resource_name"]
    }
  ]

  create_permission_model = var.permission_type != null && (var.invoker_role_name != null || var.cross_account_role_arns != null)
  permission_model        = local.create_permission_model ? { type = var.permission_type, invoker_role_name = var.invoker_role_name, cross_account_role_arns = var.cross_account_role_arns } : null
}

resource "random_id" "session" {
  byte_length = 16
}

resource "awscc_resiliencehub_app" "app" {
  name = var.app_name
  app_template_body = jsonencode({
    resources         = local.resources_json
    appComponents     = local.app_components
    excludedResources = {}
    version           = 2
  })
  resource_mappings     = local.resource_mappings
  resiliency_policy_arn = awscc_resiliencehub_resiliency_policy.policy.policy_arn
  permission_model      = local.permission_model

  tags = var.tags

  lifecycle {
    # NOTES: Emmanuel Kala
    # 
    # This is a (nasty) workaround to ignore changes to the TerraformSourceName property on
    # the ResourceMapping object. Attempts to update this property result in a HTTP
    # 400 response. Since `ignore_changes` requires static references, and computational
    # functions are not allowed here, I have created static list of 5 entries
    ignore_changes = [
      resource_mappings[0]["terraform_source_name"],
      resource_mappings[1]["terraform_source_name"],
      resource_mappings[2]["terraform_source_name"],
      resource_mappings[3]["terraform_source_name"],
      resource_mappings[4]["terraform_source_name"]
    ]
  }
}

resource "awscc_resiliencehub_resiliency_policy" "policy" {
  policy_name = "Policy-${random_id.session.id}"
  tier        = var.policy_tier
  policy = {
    AZ = {
      rto_in_secs = var.rto
      rpo_in_secs = var.rpo
    }
    Hardware = {
      rto_in_secs = var.rto
      rpo_in_secs = var.rpo
    }
    Software = {
      rto_in_secs = var.rto
      rpo_in_secs = var.rpo
    }
    Region = {
      rto_in_secs = var.rto
      rpo_in_secs = var.rpo
    }
  }

  tags = var.tags
}
