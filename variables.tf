variable "app_components" {
  type = list(object({
    app_component_name = string
    app_component_type = string
    resources = list(object({
      resource_name            = string
      resource_type            = string
      resource_identifier      = string
      resource_identifier_type = string
      resource_region          = string
    }))
  }))

  description = "The application's app-components, including its resources"
}

variable "app_name" {
  type        = string
  description = "The Application's name"
}

variable "s3_state_file_url" {
  type        = string
  description = "An URL to s3-backend Terraform state-file"
}

variable "rto" {
  type        = number
  description = "RTO across all failure metrics"
}

variable "rpo" {
  type        = number
  description = "RPO across all failure metrics"
}

variable "permission_type" {
  description = "How AWS Resilience Hub should scan the resources. Either `LegacyIAMUser` or `RoleBased`"
  type        = string
  default     = null
}

variable "invoker_role_name" {
  description = "The IAM role name that will be used by AWS Resilience Hub for read-only access to the application resources while running an assessment"
  type        = string
  default     = null
}
variable "cross_account_role_arns" {
  description = "The list of IAM Role ARNs to be used for querying purposes in other AWS accounts while importing resources and assessing your appliaction"
  type        = list(string)
  default     = []
}

variable "policy_tier" {
  description = "The tier for the resiliency policy, ranging from the highest severity (`MissionCritial`) to lowest (`NonCritical`)"
  type        = string
  default     = "MissionCritical"

  validation {
    condition     = try(index(["MissionCritical", "Critical", "Important", "CoreServices", "NonCritical", "NotApplicable"], var.policy_tier), -1) != -1
    error_message = "The policy_tier must be one of MissionCritical | Critical | Important | CoreServices | NonCritical | NotApplicable"
  }

}
variable "tags" {
  description = "Tags to be assigned to the resources"
  type        = map(string)
  default     = {}
}
