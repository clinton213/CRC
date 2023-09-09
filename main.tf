provider "aws" {
  region  = "us-east-1"
  profile = "clinamad"
}

resource "aws_s3_bucket" "mysite" {
  bucket = "clintonscloud.com"
}

resource "aws_s3_bucket_public_access_block" "mysite" {
  bucket                  = aws_s3_bucket.mysite.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "mysite" {
  bucket = aws_s3_bucket.mysite.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "mysite" {
  bucket = aws_s3_bucket.mysite.bucket
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "site_content" {
  depends_on = [
    aws_s3_bucket.mysite
  ]

  bucket                 = aws_s3_bucket.mysite.bucket
  key                    = "index.html"
  source                 = "./index.html"
  server_side_encryption = "AES256"
  content_type           = "text/html" #should be specified so content can be viewed as website instead of downloaded
}

resource "aws_s3_object" "ccp_cert" {
  bucket       = aws_s3_bucket.mysite.bucket
  key          = "AWS Certified Cloud Practitioner certificate (2).pdf"
  source       = "./AWS Certified Cloud Practitioner certificate (2).pdf"
  content_type = "application/pdf"
}

resource "aws_s3_object" "sa_cert" {
  bucket       = aws_s3_bucket.mysite.bucket
  key          = "AWS Certified Solutions Architect - Associate certificate.pdf"
  source       = "./AWS Certified Solutions Architect - Associate certificate.pdf"
  content_type = "application/pdf"
}

resource "aws_s3_object" "sysops_cert" {
  bucket       = aws_s3_bucket.mysite.bucket
  key          = "AWS Certified SysOps Administrator - Associate certificate.pdf"
  source       = "./AWS Certified SysOps Administrator - Associate certificate.pdf"
  content_type = "application/pdf"
}

resource "aws_s3_object" "terraform_cert" {
  bucket       = aws_s3_bucket.mysite.bucket
  key          = "HashiCorp_Certified__Terraform_Associate__002__Badge20230309-28-1p347jz.pdf"
  source       = "./HashiCorp_Certified__Terraform_Associate__002__Badge20230309-28-1p347jz.pdf"
  content_type = "application/pdf"
}

resource "aws_s3_object" "jscript" {
  bucket       = aws_s3_bucket.mysite.bucket
  key          = "script.js"
  source       = "./script.js"
  content_type = "application/json"
}

resource "aws_s3_object" "css" {
  bucket       = aws_s3_bucket.mysite.bucket
  key          = "style.css"
  source       = "./style.css"
  content_type = "text/css"
}

resource "aws_s3_object" "ccp_badge" {
  bucket       = aws_s3_bucket.mysite.bucket
  key          = "ccp badge.png"
  source       = "./ccp badge.png"
  content_type = "image/png"
}

resource "aws_s3_object" "sa_badge" {
  bucket       = aws_s3_bucket.mysite.bucket
  key          = "saa badge.png"
  source       = "./saa badge.png"
  content_type = "image/png"
}

resource "aws_s3_object" "sysops_badge" {
  bucket       = aws_s3_bucket.mysite.bucket
  key          = "sysops badge.png"
  source       = "./sysops badge.png"
  content_type = "image/png"
}

resource "aws_s3_object" "terraform_badge" {
  bucket       = aws_s3_bucket.mysite.bucket
  key          = "terraform badge.png"
  source       = "./terraform badge.png"
  content_type = "image/png"
}

resource "aws_s3_object" "Resume" {
  bucket       = aws_s3_bucket.mysite.bucket
  key          = "ClintonAmadiResume.docx"
  source       = "./ClintonAmadiResume.docx"
  content_type = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
}

resource "aws_s3_object" "main_img" {
  bucket       = aws_s3_bucket.mysite.bucket
  key          = "IMG_8667.jpg"
  source       = "./IMG_8667.jpg"
  content_type = "image/jpeg"
}

resource "aws_cloudfront_origin_access_control" "mysite_access" {
  name                              = "security_pillar100_cf_s3_oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "mysite_access" {
  depends_on = [
    aws_s3_bucket.mysite,
    aws_cloudfront_origin_access_control.mysite_access,
    aws_acm_certificate_validation.acm_certificate_validation

  ]

  aliases = ["clintonscloud.com", "www.clintonscloud.com"]

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = aws_s3_bucket.mysite.id
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }

    }
  }
  origin {
    domain_name              = aws_s3_bucket.mysite.bucket_domain_name
    origin_id                = aws_s3_bucket.mysite.id
    origin_access_control_id = aws_cloudfront_origin_access_control.mysite_access.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.acm_certificate.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

resource "aws_s3_bucket_policy" "mysite" {
  depends_on = [
    data.aws_iam_policy_document.mysite
  ]

  bucket = aws_s3_bucket.mysite.id
  policy = data.aws_iam_policy_document.mysite.json

}

data "aws_iam_policy_document" "mysite" {
  depends_on = [
    aws_cloudfront_distribution.mysite_access,
    aws_s3_bucket.mysite
  ]

  statement {
    sid    = "AllowCloudFrontService"
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]

    principals {
      identifiers = ["cloudfront.amazonaws.com"]
      type        = "Service"
    }

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.mysite.bucket}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"

      values = [aws_cloudfront_distribution.mysite_access.arn]
    }
  }
}

resource "aws_acm_certificate" "acm_certificate" {
  domain_name               = "clintonscloud.com"
  subject_alternative_names = ["*.clintonscloud.com"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_route53_zone" "route53_zone" {
  name = "clintonscloud.com"
}

resource "aws_route53_record" "route53_record" {
  for_each = {
    for dvo in aws_acm_certificate.acm_certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.route53_zone.zone_id
}

resource "aws_acm_certificate_validation" "acm_certificate_validation" {
  certificate_arn         = aws_acm_certificate.acm_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.route53_record : record.fqdn]
}

resource "aws_route53_record" "cloudfront_record" {
  zone_id = data.aws_route53_zone.route53_zone.zone_id
  name    = "clintonscloud.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.mysite_access.domain_name
    zone_id                = aws_cloudfront_distribution.mysite_access.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_cloudfront_record" {
  zone_id = data.aws_route53_zone.route53_zone.zone_id
  name    = "www.clintonscloud.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.mysite_access.domain_name
    zone_id                = aws_cloudfront_distribution.mysite_access.hosted_zone_id
    evaluate_target_health = false
  }
}
